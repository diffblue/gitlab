# frozen_string_literal: true

# Create a separate process, which does not load the Rails environment, to index
# each repository. This prevents memory leaks in the indexer from affecting the
# rest of the application.
module Gitlab
  module Elastic
    class Indexer
      include Gitlab::Utils::StrongMemoize
      include Gitlab::Loggable

      Error = Class.new(StandardError)

      class << self
        def indexer_version
          Rails.root.join('GITLAB_ELASTICSEARCH_INDEXER_VERSION').read.chomp
        end

        def timeout
          if Feature.enabled?(:advanced_search_decrease_indexing_timeout)
            30.minutes.to_i
          else
            1.day.to_i
          end
        end
      end

      attr_reader :project, :group, :index_status, :wiki, :force
      alias_method :index_wiki?, :wiki
      alias_method :force_reindexing?, :force

      def initialize(project, wiki: false, force: false)
        @project = project
        @group = project.group
        @wiki = wiki
        @force = force

        # Use the eager-loaded association if available.
        @index_status = project.index_status
      end

      # Runs the indexation process, which is the following:
      # - Purge the index for any unreachable commits;
      # - Run the `gitlab-elasticsearch-indexer`;
      # - Update the `index_status` for the associated project;
      #
      # ref - Git ref up to which the indexation will run (default: HEAD)
      def run(ref = 'HEAD')
        commit = find_indexable_commit(ref)
        return update_index_status(Gitlab::Git::BLANK_SHA) unless commit

        repository.__elasticsearch__.elastic_writing_targets.each do |target|
          logger.debug(build_structured_payload(message: 'indexing_commit_range',
                                                group_id: group&.id,
                                                project_id: project.id,
                                                from_sha: from_sha,
                                                to_sha: commit.sha,
                                                index_wiki: index_wiki?
                                               )
                      )

          # This might happen when default branch has been reset or rebased.
          base_sha = if purge_unreachable_commits_from_index?(commit.sha)
                       purge_unreachable_commits_from_index!(target)

                       Gitlab::Git::EMPTY_TREE_ID
                     else
                       from_sha
                     end

          run_indexer!(base_sha, commit.sha, target)
        end

        # update the index status only if all writes were successful
        update_index_status(commit.sha)

        true
      end

      def find_indexable_commit(ref)
        !repository.empty? && repository.commit(ref)
      end

      def purge_unreachable_commits_from_index?(to_sha)
        force_reindexing? || !last_commit_ancestor_of?(to_sha)
      end

      private

      def repository
        index_wiki? ? project.wiki.repository : project.repository
      end

      def run_indexer!(base_sha, to_sha, target)
        vars = build_envvars(target)
        command = build_command(base_sha, to_sha)

        output, status = Gitlab::Popen.popen(command, nil, vars)

        return if status.blank?

        payload = build_structured_payload(
          message: output,
          status: status,
          group_id: group&.id,
          project_id: project.id,
          from_sha: base_sha,
          to_sha: to_sha,
          index_wiki: index_wiki?
        )

        if status == 0
          logger.info(payload)
        else
          logger.error(payload)
          raise Error, output
        end
      end

      # Remove all indexed data for commits and blobs for a project.
      #
      # @return: whether the index has been purged
      def purge_unreachable_commits_from_index!(target)
        target.delete_index_for_commits_and_blobs(wiki: index_wiki?)
      rescue ::Elasticsearch::Transport::Transport::Errors::BadRequest => e
        Gitlab::ErrorTracking.track_exception(e, group_id: group&.id, project_id: project.id)
      end

      def build_envvars(target)
        # We accept any form of settings, including string and array
        # This is why JSON is needed
        vars = {
          'RAILS_ENV' => Rails.env,
          'ELASTIC_CONNECTION_INFO' => elasticsearch_config(target),
          'GITALY_CONNECTION_INFO' => gitaly_config,
          'CORRELATION_ID' => Labkit::Correlation::CorrelationId.current_id,
          'SSL_CERT_FILE' => Gitlab::X509::Certificate.default_cert_file,
          'SSL_CERT_DIR' => Gitlab::X509::Certificate.default_cert_dir
        }

        # Set AWS environment variables for IAM role authentication if present
        if Gitlab::CurrentSettings.elasticsearch_config[:aws]
          vars = build_aws_credentials_env(vars)
        end

        # Users can override default SSL certificate path via SSL_CERT_FILE SSL_CERT_DIR
        vars.merge(ENV.slice('SSL_CERT_FILE', 'SSL_CERT_DIR'))
      end

      def build_command(base_sha, to_sha)
        path_to_indexer = Gitlab.config.elasticsearch.indexer_path
        timeout_argument = "--timeout=#{self.class.timeout}s"
        visibility_level_argument = "--visibility-level=#{project.visibility_level}"

        command = [path_to_indexer, timeout_argument, visibility_level_argument]

        command << "--group-id=#{group.id}" if group
        command << "--project-id=#{project.id}" if project
        command << '--search-curation' if Feature.enabled?(:search_index_curation)
        command << "--from-sha=#{base_sha}"
        command << "--to-sha=#{to_sha}"
        command << "--full-path=#{project.full_path}"

        command += if index_wiki?
                     %W[--blob-type=wiki_blob --skip-commits --wiki-access-level=#{project.wiki_access_level}]
                   else
                     %W[--repository-access-level=#{project.repository_access_level}].tap do |c|
                       migration_name = :add_hashed_root_namespace_id_to_commits
                       migration_done = ::Elastic::DataMigrationService.migration_has_finished?(migration_name)

                       c << "--hashed-root-namespace-id=#{project.namespace.hashed_root_namespace_id}" if migration_done
                     end
                   end

        command << "--traversal-ids=#{project.namespace_ancestry}"

        command << repository_path
      end

      def build_aws_credentials_env(vars)
        # AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN need to be set as
        # environment variable in case of using IAM role based authentication in AWS
        # The credentials are buffered to prevent from hitting rate limit. They will be
        # refreshed when expired
        credentials = Gitlab::Elastic::Client.aws_credential_provider&.credentials
        return vars unless credentials&.set?

        vars.merge(
          'AWS_ACCESS_KEY_ID' => credentials.access_key_id,
          'AWS_SECRET_ACCESS_KEY' => credentials.secret_access_key,
          'AWS_SESSION_TOKEN' => credentials.session_token
        )
      end

      def last_commit
        index_wiki? ? index_status&.last_wiki_commit : index_status&.last_commit
      end

      def from_sha
        strong_memoize(:from_sha) do
          repository_contains_last_indexed_commit? ? last_commit : Gitlab::Git::EMPTY_TREE_ID
        end
      end

      def repository_contains_last_indexed_commit?
        strong_memoize(:repository_contains_last_indexed_commit) do
          last_commit.present? && repository.commit(last_commit).present?
        end
      end

      def last_commit_ancestor_of?(to_sha)
        return true if from_sha == Gitlab::Git::BLANK_SHA
        return false unless repository_contains_last_indexed_commit?

        # we always treat the `EMPTY_TREE_ID` as an ancestor to make sure
        # we don't try to purge an empty index
        from_sha == Gitlab::Git::EMPTY_TREE_ID || repository.ancestor?(from_sha, to_sha)
      end

      def repository_path
        "#{repository.disk_path}.git"
      end

      def elasticsearch_config(target)
        config = Gitlab::CurrentSettings.elasticsearch_config.merge(
          index_name: target.index_name,
          index_name_commits: ::Elastic::Latest::CommitConfig.index_name
        )

        if ::Elastic::DataMigrationService.migration_has_finished?(:migrate_wikis_to_separate_index)
          config[:index_name_wikis] = ::Elastic::Latest::WikiConfig.index_name
        end

        # We need to pass a percent encoded URL string instead of a hash
        # to the go indexer because it passes authentication credentials
        # embedded in the url.
        #
        # See:
        # https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer/blob/main/elastic/elastic.go#L22
        config[:url] = config[:url].map { |u| ::Gitlab::Elastic::Helper.url_string(u) }
        config.to_json
      end

      def gitaly_config
        {
          storage: project.repository_storage,
          limit_file_size: Gitlab::CurrentSettings.elasticsearch_indexed_file_size_limit_kb.kilobytes
        }.merge(Gitlab::GitalyClient.connection_data(project.repository_storage)).to_json
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def update_index_status(to_sha)
        unless Project.exists?(id: project.id)
          logger.debug(build_structured_payload(
            message: "Index status not updated. The project does not exist.",
            group_id: group&.id,
            project_id: project.id,
            index_wiki: index_wiki?
          ))
          return false
        end

        raise "Invalid sha #{to_sha}" unless to_sha.present?

        # An index_status should always be created,
        # even if the repository is empty, so we know it's been looked at.
        @index_status ||= IndexStatus.safe_find_or_create_by!(project_id: project.id)

        attributes = if index_wiki?
                       { last_wiki_commit: to_sha, wiki_indexed_at: Time.now }
                     else
                       { last_commit: to_sha, indexed_at: Time.now }
                     end

        @index_status.update!(attributes)

        project.reload_index_status
      rescue ActiveRecord::InvalidForeignKey
        logger.debug(
          build_structured_payload(message: "Index status not created, project not found",
                                   group_id: group&.id, project_id: project.id)
        )
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def logger
        @logger ||= ::Gitlab::Elasticsearch::Logger.build
      end
    end
  end
end
