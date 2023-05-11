# frozen_string_literal: true

module Elastic
  module Latest
    module GitClassProxy
      SHA_REGEX = /\A[0-9a-f]{5,40}\z/i.freeze
      HIGHLIGHT_START_TAG = 'gitlabelasticsearch→'
      HIGHLIGHT_END_TAG = '←gitlabelasticsearch'
      MAX_LANGUAGES = 100

      def elastic_search(query, type: 'all', page: 1, per: 20, options: {})
        results = { blobs: [], commits: [] }

        case type
        when 'all'
          results[:commits] = search_commit(query, page: page, per: per, options: options.merge(features: 'repository'))
          results[:blobs] = search_blob(query, type: 'blob', page: page, per: per, options: options.merge(features: 'repository'))
          results[:wiki_blobs] = search_blob(query, type: 'wiki_blob', page: page, per: per, options: options.merge(features: 'wiki'))
        when 'commit'
          results[:commits] = search_commit(query, page: page, per: per, options: options.merge(features: 'repository'))
        when 'blob'
          results[:blobs] = search_blob(query, type: type, page: page, per: per, options: options.merge(features: 'repository'))
        when 'wiki_blob'
          results[:wiki_blobs] = search_blob(query, type: type, page: page, per: per, options: options.merge(features: 'wiki'))
        end

        results
      end

      # @return [Kaminari::PaginatableArray]
      def elastic_search_as_found_blob(query, page: 1, per: 20, options: {}, preload_method: nil)
        # Highlight is required for parse_search_result to locate relevant line
        options = options.merge(highlight: true)

        elastic_search_and_wrap(query, type: es_type, page: page, per: per, options: options, preload_method: preload_method) do |result, project|
          ::Gitlab::Elastic::SearchResults.parse_search_result(result, project)
        end
      end

      def blob_aggregations(query, options)
        query_hash, options = blob_query(query, options: options.merge(features: 'repository', aggregation: true))

        results = search(query_hash, options)

        ::Gitlab::Search::AggregationParser.call(results.response.aggregations)
      end

      private

      def should_use_project_ids_filter?(options)
        options[:project_ids] == :any || options[:group_ids].blank?
      end

      def authorization_filter(query_hash, options)
        return project_ids_filter(query_hash, options) if should_use_project_ids_filter?(options)

        current_user = options[:current_user]
        namespaces = Namespace.find(authorized_namespace_ids(current_user, options))
        traversal_ids = namespaces.map(&:elastic_namespace_ancestry)

        return project_ids_filter(query_hash, options) if traversal_ids.blank?

        context.name(:reject_projects) do
          query_hash[:query][:bool][:must_not] ||= []
          query_hash[:query][:bool][:must_not] << rejected_project_filter(namespaces, options)
        end

        context.name(:namespace) do
          query_hash[:query][:bool][:filter] ||= []
          query_hash[:query][:bool][:filter] << ancestry_filter(current_user, traversal_ids, prefix: :traversal_ids)
        end

        query_hash
      end

      def options_filter_context(type, options)
        repository_ids = [options[:repository_id]].flatten
        languages = [options[:language]].flatten

        filters = []

        if repository_ids.any?
          if options[:features].eql?('wiki') && !::Elastic::DataMigrationService.migration_has_finished?(:add_suffix_project_in_wiki_rid)
            repository_ids = repository_ids.flat_map do |rid|
              rid =~ /wiki_project_\d+/ ? [rid, rid.gsub(/wiki_project/, 'wiki')] : rid
            end.uniq
          end

          filters << {
            terms: {
              _name: context.name(type, :related, :repositories),
              (options[:project_id_field] || "#{type}.rid") => repository_ids
            }
          }
        end

        if languages.any? && type == :blob && (!options[:count_only] || options[:aggregation])
          filters << {
            terms: {
              _name: context.name(type, :match, :languages),
              "#{type}.language" => languages
            }
          }
        end

        filters << options[:additional_filter] if options[:additional_filter]

        { filter: filters }
      end

      # rubocop:disable Metrics/AbcSize
      def search_commit(query, page: 1, per: 20, options: {})
        fields = %w(message^10 sha^5 author.name^2 author.email^2 committer.name committer.email)
        query_with_prefix = query.split(/\s+/).map { |s| s.gsub(SHA_REGEX) { |sha| "#{sha}*" } }.join(' ')

        bool_expr = ::Gitlab::Elastic::BoolExpr.new

        options[:no_join_project] = true
        options[:index_name] = Elastic::Latest::CommitConfig.index_name
        options[:project_id_field] = 'rid'

        query_hash = {
          query: { bool: bool_expr },
          size: (options[:count_only] ? 0 : per),
          from: per * (page - 1),
          sort: [:_score]
        }

        # If there is a :current_user set in the `options`, we can assume
        # we need to do a project visibility check.
        #
        # Note that `:current_user` might be `nil` for a anonymous user
        query_hash = context.name(:commit, :authorized) { project_ids_filter(query_hash, options) } if options.key?(:current_user)

        bool_expr = apply_simple_query_string(
          name: context.name(:commit, :match, :search_terms),
          fields: fields,
          query: query_with_prefix,
          bool_expr: bool_expr,
          count_only: options[:count_only]
        )

        # add the document type filter
        bool_expr[:filter] << {
          term: {
            type: {
              _name: context.name(:doc, :is_a, :commit),
              value: 'commit'
            }
          }
        }

        # add filters extracted from the options
        options_filter_context = options_filter_context(:commit, options)
        bool_expr[:filter] += options_filter_context[:filter] if options_filter_context[:filter].any?

        options[:order] = :default if options[:order].blank?

        if options[:highlight] && !options[:count_only]
          es_fields = fields.map { |field| field.split('^').first }.each_with_object({}) do |field, memo|
            memo[field.to_sym] = {}
          end

          query_hash[:highlight] = {
            pre_tags: [HIGHLIGHT_START_TAG],
            post_tags: [HIGHLIGHT_END_TAG],
            fields: es_fields
          }
        end

        res = search(query_hash, options)
        {
          results: res.results,
          total_count: res.size
        }
      end

      def search_blob(query, type: 'blob', page: 1, per: 20, options: {})
        query_hash, options = blob_query(query, type: type, page: page, per: per, options: options)

        res = search(query_hash, options)

        {
          results: res.results,
          total_count: res.size
        }
      end

      # Wrap returned results into GitLab model objects and paginate
      #
      # @return [Kaminari::PaginatableArray]
      def elastic_search_and_wrap(query, type:, page: 1, per: 20, options: {}, preload_method: nil, &blk)
        response = elastic_search(
          query,
          type: type,
          page: page,
          per: per,
          options: options
        )[type.pluralize.to_sym][:results]

        items, total_count = yield_each_search_result(response, type, preload_method, &blk)

        # Before "map" we had a paginated array so we need to recover it
        offset = per * ((page || 1) - 1)
        Kaminari.paginate_array(items, total_count: total_count, limit: per, offset: offset)
      end

      def yield_each_search_result(response, type, preload_method)
        # Avoid one SELECT per result by loading all projects into a hash
        project_ids = response.map { |result| project_id_for_commit_or_blob(result, type) }.uniq
        projects = Project.with_route.id_in(project_ids)
        projects = projects.public_send(preload_method) if preload_method # rubocop:disable GitlabSecurity/PublicSend
        projects = projects.index_by(&:id)
        total_count = response.total_count

        items = response.map do |result|
          project_id = project_id_for_commit_or_blob(result, type)
          project = projects[project_id]

          if project.nil? || project.pending_delete?
            total_count -= 1
            next
          end

          yield(result, project)
        end

        # Remove results for deleted projects
        items.compact!

        [items, total_count]
      end

      # Indexed commit does not include project_id
      def project_id_for_commit_or_blob(result, type)
        (result.dig('_source', 'project_id') || result.dig('_source', type, 'rid') || result.dig('_source', 'rid')).to_i
      end

      def apply_simple_query_string(name:, fields:, query:, bool_expr:, count_only:)
        fields = remove_fields_boost(fields) if count_only

        simple_query_string = {
          simple_query_string: {
            _name: name,
            fields: fields,
            query: query,
            default_operator: :and
          }
        }

        bool_expr.tap do |expr|
          if count_only
            expr[:filter] << simple_query_string
          else
            expr[:must] = simple_query_string
          end
        end
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      def blob_query(query, type: 'blob', page: 1, per: 20, options: {})
        aggregation = options[:aggregation]
        count_only = options[:count_only]

        query = ::Gitlab::Search::Query.new(query) do
          filter :filename, field: :file_name
          filter :path, parser: ->(input) { "#{input.downcase}*" }

          if Feature.enabled?(:elastic_file_name_reverse_optimization)
            filter :extension, field: 'file_name.reverse', type: :prefix, parser: ->(input) { input.downcase.reverse + '.' }
          else
            filter :extension, field: :path, parser: ->(input) { '*.' + input.downcase }
          end

          filter :blob, field: :oid
        end

        bool_expr = ::Gitlab::Elastic::BoolExpr.new
        count_or_aggregation_query = count_only || aggregation
        query_hash = {
          query: { bool: bool_expr },
          size: (count_or_aggregation_query ? 0 : per)
        }

        unless aggregation
          query_hash[:from] = per * (page - 1)
          query_hash[:sort] = [:_score]
        end

        if options[:features].eql?('wiki')
          options[:no_join_project] = Elastic::DataMigrationService.migration_has_finished?(:backfill_wiki_permissions_in_main_index)
        end

        if use_separate_wiki_index? options[:features]
          fields = %w[content file_name path]
          options[:index_name] = Elastic::Latest::WikiConfig.index_name
        else
          fields = %w[blob.content blob.file_name blob.path]
        end

        bool_expr = apply_simple_query_string(
          name: context.name(:blob, :match, :search_terms),
          query: query.term,
          fields: fields,
          bool_expr: bool_expr,
          count_only: options[:count_only]
        )

        # If there is a :current_user set in the `options`, we can assume
        # we need to do a project visibility check.
        #
        # Note that `:current_user` might be `nil` for a anonymous user
        if options.key?(:current_user)
          query_hash = context.name(:blob, :authorized) { authorization_filter(query_hash, options) }
        end

        # add the document type filter
        bool_expr[:filter] << {
          term: {
            type: {
              _name: context.name(:doc, :is_a, type),
              value: type
            }
          }
        }

        # add filters extracted from the query
        query_filter_context = query.elasticsearch_filter_context(:blob)
        bool_expr[:filter] += query_filter_context[:filter] if query_filter_context[:filter].any?
        bool_expr[:must_not] += query_filter_context[:must_not] if query_filter_context[:must_not].any?

        # add filters extracted from the `options`
        options[:project_id_field] = use_separate_wiki_index?(options[:features]) ? 'rid' : 'blob.rid'
        options_filter_context = options_filter_context(:blob, options)
        bool_expr[:filter] += options_filter_context[:filter] if options_filter_context[:filter].any?
        options[:order] = :default if options[:order].blank? && !aggregation

        if options[:highlight] && !count_or_aggregation_query
          query_hash[:highlight] = {
            pre_tags: [HIGHLIGHT_START_TAG],
            post_tags: [HIGHLIGHT_END_TAG],
            number_of_fragments: 0, # highlighted text fragments do not work well for code as we want to show a few whole lines of code. We need to get the whole content to determine the exact line number that was highlighted.
            fields: {
              "blob.content" => {},
              "blob.file_name" => {}
            }
          }
        end

        if type == 'blob' && aggregation
          query_hash[:aggs] = {
            language: {
              terms: {
                field: 'blob.language',
                size: MAX_LANGUAGES
              }
            }
          }
        end

        # inject the `id` part of repository as project id
        repository_ids = [options[:repository_id]].flatten
        options[:project_ids] = repository_ids.map { |id| id.to_s[/\d+/].to_i } if type == 'wiki_blob' && repository_ids.any?

        [query_hash, options]
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity

      def use_separate_wiki_index?(feature)
        feature.eql?('wiki') && Elastic::DataMigrationService.migration_has_finished?(:migrate_wikis_to_separate_index)
      end
    end
  end
end
