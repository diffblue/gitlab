# frozen_string_literal: true

module Gitlab
  module Elastic
    class SearchResults
      include ActionView::Helpers::NumberHelper
      include Gitlab::Utils::StrongMemoize

      ELASTIC_COUNT_LIMIT = 10000
      DEFAULT_PER_PAGE = Gitlab::SearchResults::DEFAULT_PER_PAGE

      attr_reader :current_user, :query, :public_and_internal_projects, :order_by, :sort, :filters

      # Limit search results by passed projects
      # It allows us to search only for projects user has access to
      attr_reader :limit_project_ids

      def initialize(current_user, query, limit_project_ids = nil, public_and_internal_projects: true, order_by: nil, sort: nil, filters: {})
        @current_user = current_user
        @query = query
        @limit_project_ids = limit_project_ids
        @public_and_internal_projects = public_and_internal_projects
        @order_by = order_by
        @sort = sort
        @filters = filters
      end

      def objects(scope, page: 1, per_page: DEFAULT_PER_PAGE, preload_method: nil)
        page = (page || 1).to_i

        case scope
        when 'projects'
          eager_load(projects, page, per_page, preload_method, [:route, :namespace, :topics])
        when 'issues'
          eager_load(issues, page, per_page, preload_method, project: [:route, :namespace], labels: [], timelogs: [], assignees: [])
        when 'merge_requests'
          eager_load(merge_requests, page, per_page, preload_method, target_project: [:route, :namespace])
        when 'milestones'
          eager_load(milestones, page, per_page, preload_method, project: [:route, :namespace])
        when 'notes'
          eager_load(notes, page, per_page, preload_method, project: [:route, :namespace])
        when 'blobs'
          blobs(page: page, per_page: per_page, preload_method: preload_method)
        when 'wiki_blobs'
          wiki_blobs(page: page, per_page: per_page)
        when 'commits'
          commits(page: page, per_page: per_page, preload_method: preload_method)
        when 'users'
          users(page: page, per_page: per_page, preload_method: preload_method)
        else
          Kaminari.paginate_array([])
        end
      end

      # Pull the highlight attribute out of Elasticsearch results
      # and map it to the result id
      def highlight_map(scope)
        results = case scope
                  when 'projects'
                    projects
                  when 'issues'
                    issues
                  when 'merge_requests'
                    merge_requests
                  when 'milestones'
                    milestones
                  when 'notes'
                    notes
                  end

        results.to_h { |x| [x[:_source][:id], x[:highlight]] } if results.present?
      end

      def formatted_count(scope)
        case scope
        when 'projects'
          elastic_search_limited_counter_with_delimiter(projects_count)
        when 'notes'
          elastic_search_limited_counter_with_delimiter(notes_count)
        when 'blobs'
          elastic_search_limited_counter_with_delimiter(blobs_count)
        when 'wiki_blobs'
          elastic_search_limited_counter_with_delimiter(wiki_blobs_count)
        when 'commits'
          elastic_search_limited_counter_with_delimiter(commits_count)
        when 'issues'
          elastic_search_limited_counter_with_delimiter(issues_count)
        when 'merge_requests'
          elastic_search_limited_counter_with_delimiter(merge_requests_count)
        when 'milestones'
          elastic_search_limited_counter_with_delimiter(milestones_count)
        when 'users'
          elastic_search_limited_counter_with_delimiter(users_count)
        end
      end

      def projects_count
        @projects_count ||= if strong_memoized?(:projects)
                              projects.total_count
                            else
                              projects(count_only: true).total_count
                            end
      end

      def notes_count
        @notes_count ||= if strong_memoized?(:notes)
                           notes.total_count
                         else
                           notes(count_only: true).total_count
                         end
      end

      def users_count
        @users_count ||= if strong_memoized?(:users)
                           users.total_count
                         else
                           users(count_only: true).total_count
                         end
      end

      def blobs_count
        @blobs_count ||= if strong_memoized?(:blobs)
                           blobs.total_count
                         else
                           blobs(count_only: true).total_count
                         end
      end

      def wiki_blobs_count
        @wiki_blobs_count ||= if strong_memoized?(:wiki_blobs)
                                wiki_blobs.total_count
                              else
                                wiki_blobs(count_only: true).total_count
                              end
      end

      def commits_count
        @commits_count ||= if strong_memoized?(:commits)
                             commits.total_count
                           else
                             commits(count_only: true).total_count
                           end
      end

      def issues_count
        @issues_count ||= if strong_memoized?(:issues)
                            issues.total_count
                          else
                            issues(count_only: true).total_count
                          end
      end

      def merge_requests_count
        @merge_requests_count ||= if strong_memoized?(:merge_requests)
                                    merge_requests.total_count
                                  else
                                    merge_requests(count_only: true).total_count
                                  end
      end

      def milestones_count
        @milestones_count ||= if strong_memoized?(:milestones)
                                milestones.total_count
                              else
                                milestones(count_only: true).total_count
                              end
      end

      # mbergeron: these aliases act as an adapter to the Gitlab::SearchResults
      # interface, which is mostly implemented by this class.
      alias_method :limited_projects_count, :projects_count
      alias_method :limited_notes_count, :notes_count
      alias_method :limited_blobs_count, :blobs_count
      alias_method :limited_wiki_blobs_count, :wiki_blobs_count
      alias_method :limited_commits_count, :commits_count
      alias_method :limited_issues_count, :issues_count
      alias_method :limited_merge_requests_count, :merge_requests_count
      alias_method :limited_milestones_count, :milestones_count

      def self.parse_search_result(result, project)
        path = extract_path_from_result result['_source']
        basename = File.join(File.dirname(path), File.basename(path, '.*'))
        content = extract_content_from_result(result['_source'])
        project_id = result['_source']['project_id'].to_i
        total_lines = content.lines.size

        highlight_content = get_highlight_content result

        found_line_number = 0
        highlight_found = false
        matched_lines_count = highlight_content.scan(/#{::Elastic::Latest::GitClassProxy::HIGHLIGHT_START_TAG}(.*?)\R/o).size

        highlight_content.each_line.each_with_index do |line, index|
          next unless line.include?(::Elastic::Latest::GitClassProxy::HIGHLIGHT_START_TAG)

          found_line_number = index
          highlight_found = true
          break
        end

        from = if found_line_number >= 2
                 found_line_number - 2
               else
                 found_line_number
               end

        to = if (total_lines - found_line_number) > 3
               found_line_number + 2
             else
               found_line_number
             end

        data = content.lines[from..to]
        # only send highlighted line number if a highlight was returned by Elasticsearch
        highlight_line = highlight_found ? found_line_number + 1 : nil

        ::Gitlab::Search::FoundBlob.new(
          path: path,
          basename: basename,
          ref: extract_ref_from_result(result['_source']),
          matched_lines_count: matched_lines_count,
          startline: from + 1,
          highlight_line: highlight_line,
          data: data.join,
          project: project,
          project_id: project_id
        )
      end

      def aggregations(scope)
        case scope
        when 'blobs'
          blob_aggregations
        when 'issues'
          issue_aggregations
        else
          []
        end
      end

      private

      # Apply some eager loading to the `records` of an ES result object without
      # losing pagination information. Also, take advantage of preload method if
      # provided by the caller.
      def eager_load(es_result, page, per_page, preload_method, eager)
        paginated_base = es_result.page(page).per(per_page)
        relation = paginated_base.records.includes(eager) # rubocop:disable CodeReuse/ActiveRecord
        relation = relation.public_send(preload_method) if preload_method # rubocop:disable GitlabSecurity/PublicSend

        Kaminari.paginate_array(
          relation.to_a,
          total_count: paginated_base.total_count,
          limit: per_page,
          offset: per_page * (page - 1)
        )
      end

      def base_options
        {
          current_user: current_user,
          project_ids: limit_project_ids,
          public_and_internal_projects: public_and_internal_projects,
          order_by: order_by,
          sort: sort
        }
      end

      def scope_options(scope)
        case scope
        when :merge_requests
          base_options.merge(filters.slice(:order_by, :sort, :state))
        when :issues
          base_options.merge(filters.slice(:order_by, :sort, :confidential, :state))
        when :milestones
          # Must pass 'issues' and 'merge_requests' to check
          # if any of the features is available for projects in ApplicationClassProxy#project_ids_query
          # Otherwise it will ignore project_ids and return milestones
          # from projects with milestones disabled.
          base_options.merge(features: [:issues, :merge_requests])
        when :users
          base_options.merge(admin: current_user&.admin?, routing_disabled: true) # rubocop:disable Cop/UserAdmin
        when :blobs
          base_options.merge(filters.slice(:language))
        else
          base_options
        end
      end

      def scope_results(scope, klass, count_only:)
        options = scope_options(scope).merge(count_only: count_only)

        strong_memoize(memoize_key(scope, count_only: count_only)) do
          klass.elastic_search(query, options: options)
        end
      end

      def memoize_key(scope, count_only:)
        count_only ? "#{scope}_results_count".to_sym : scope
      end

      def projects(count_only: false)
        scope_results :projects, Project, count_only: count_only
      end

      def issues(count_only: false)
        scope_results :issues, Issue, count_only: count_only
      end

      def milestones(count_only: false)
        scope_results :milestones, Milestone, count_only: count_only
      end

      def merge_requests(count_only: false)
        scope_results :merge_requests, MergeRequest, count_only: count_only
      end

      def notes(count_only: false)
        scope_results :notes, Note, count_only: count_only
      end

      def users(page: 1, per_page: DEFAULT_PER_PAGE, count_only: false, preload_method: nil)
        return Kaminari.paginate_array([]) unless allowed_to_read_users?

        strong_memoize(memoize_key(:users, count_only: count_only)) do
          users = scope_results(:users, User, count_only: count_only)
          eager_load(users, page, per_page, preload_method, [:status])
        end
      end

      def blobs(page: 1, per_page: DEFAULT_PER_PAGE, count_only: false, preload_method: nil)
        return Kaminari.paginate_array([]) if query.blank?

        strong_memoize(memoize_key(:blobs, count_only: count_only)) do
          Repository.__elasticsearch__.elastic_search_as_found_blob(
            query,
            page: (page || 1).to_i,
            per: per_page,
            options: scope_options(:blobs).merge(count_only: count_only),
            preload_method: preload_method
          )
        end
      end

      def wiki_blobs(page: 1, per_page: DEFAULT_PER_PAGE, count_only: false)
        return Kaminari.paginate_array([]) if query.blank?

        strong_memoize(memoize_key(:wiki_blobs, count_only: count_only)) do
          ProjectWiki.__elasticsearch__.elastic_search_as_wiki_page(
            query,
            page: (page || 1).to_i,
            per: per_page,
            options: scope_options(:wiki_blobs).merge(count_only: count_only)
          )
        end
      end

      # We're only memoizing once because this object only ever gets used to show a single page of results
      # during its lifetime. We _must_ memoize the page we want because `#commits_count` does not have any
      # inkling of the current page we're on - if we were to memoize with dynamic parameters we would end up
      # hitting ES twice for any page that's not page 1, and that's something we want to avoid.
      #
      # It is safe to memoize the page we get here because this method is _always_ called before `#commits_count`
      def commits(page: 1, per_page: DEFAULT_PER_PAGE, preload_method: nil, count_only: false)
        return Kaminari.paginate_array([]) if query.blank?

        strong_memoize(memoize_key(:commits, count_only: count_only)) do
          Repository.find_commits_by_message_with_elastic(
            query,
            page: (page || 1).to_i,
            per_page: per_page,
            options: scope_options(:commits).merge(count_only: count_only),
            preload_method: preload_method
          )
        end
      end

      def default_scope
        'projects'
      end

      def elastic_search_limited_counter_with_delimiter(count)
        if count.nil?
          number_with_delimiter(0)
        elsif count >= ELASTIC_COUNT_LIMIT
          number_with_delimiter(ELASTIC_COUNT_LIMIT) + '+'
        else
          number_with_delimiter(count)
        end
      end

      def blob_aggregations
        strong_memoize(:blob_aggregations) do
          Repository.__elasticsearch__.blob_aggregations(query, base_options)
        end
      end

      def issue_aggregations
        strong_memoize(:issue_aggregations) do
          Issue.__elasticsearch__.issue_aggregations(query, base_options)
        end
      end

      def allowed_to_read_users?
        Ability.allowed?(current_user, :read_users_list)
      end

      def self.use_separate_wiki_index?(type)
        type.eql?('wiki_blob') && ::Elastic::DataMigrationService.migration_has_finished?(:migrate_wikis_to_separate_index)
      end

      def self.extract_ref_from_result(source)
        use_separate_wiki_index?(source['type']) ? source['commit_sha'] : source['blob']['commit_sha']
      end

      def self.extract_path_from_result(source)
        (use_separate_wiki_index?(source['type']) ? source['path'] : source['blob']['path']) || ''
      end

      def self.extract_content_from_result(source)
        use_separate_wiki_index?(source['type']) ? source['content'] : source['blob']['content']
      end

      def self.get_highlight_content(result)
        content_key = use_separate_wiki_index?(result['_source']['type']) ? 'content' : 'blob.content'
        result.dig('highlight', content_key)&.first || ''
      end
    end
  end
end
