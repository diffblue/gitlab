# frozen_string_literal: true

module Gitlab
  module Zoekt
    class SearchResults
      include ActionView::Helpers::NumberHelper
      include Gitlab::Utils::StrongMemoize

      DEFAULT_PER_PAGE = Gitlab::SearchResults::DEFAULT_PER_PAGE

      attr_reader :current_user, :query, :public_and_internal_projects, :order_by, :sort, :filters, :error

      # Limit search results by passed projects
      # It allows us to search only for projects user has access to
      attr_reader :limit_project_ids

      def initialize(current_user, query, limit_project_ids = nil, order_by: nil, sort: nil, filters: {})
        @current_user = current_user
        @query = query
        @limit_project_ids = limit_project_ids
        @order_by = order_by
        @sort = sort
        @filters = filters
      end

      def objects(scope, page: 1, per_page: DEFAULT_PER_PAGE, preload_method: nil)
        blobs(page: page, per_page: per_page, preload_method: preload_method)
      end

      def formatted_count(scope)
        limited_counter_with_delimiter(blobs_count)
      end

      def blobs_count
        @blobs_count ||= blobs.total_count
      end

      # These aliases act as an adapter to the Gitlab::SearchResults
      # interface, which is mostly implemented by this class.
      alias_method :limited_blobs_count, :blobs_count

      def parse_zoekt_search_result(result, project)
        ref = project.default_branch_or_main
        path = result[:path]
        basename = File.join(File.dirname(path), File.basename(path, '.*'))
        content = result[:content]
        project_id = project.id

        ::Gitlab::Search::FoundBlob.new(
          path: path,
          basename: basename,
          ref: ref,
          startline: [result[:line] - 1, 0].max,
          highlight_line: result[:line],
          data: content,
          project: project,
          project_id: project_id
        )
      end

      def aggregations(scope)
        []
      end

      def highlight_map(_)
        nil
      end

      def failed?
        error.present?
      end

      private

      def base_options
        {
          current_user: current_user,
          project_ids: limit_project_ids,
          public_and_internal_projects: public_and_internal_projects,
          order_by: order_by,
          sort: sort
        }
      end

      def memoize_key(scope, page:, per_page:, count_only:)
        count_only ? "#{scope}_results_count".to_sym : "#{scope}_#{page}_#{per_page}"
      end

      def blobs(page: 1, per_page: DEFAULT_PER_PAGE, count_only: false, preload_method: nil)
        return Kaminari.paginate_array([]) if query.blank?

        strong_memoize(memoize_key(:blobs, page: page, per_page: per_page, count_only: count_only)) do
          search_as_found_blob(
            query,
            Repository,
            page: (page || 1).to_i,
            per_page: per_page,
            options: base_options.merge(count_only: count_only).merge(filters.slice(:language)),
            preload_method: preload_method
          )
        end
      end

      def limited_counter_with_delimiter(count)
        number_with_delimiter(count)
      end

      def search_as_found_blob(query, repositories, page:, per_page:, options:, preload_method:)
        zoekt_search_and_wrap(query, page: page,
                              per_page: per_page,
                              options: options,
                              preload_method: preload_method) do |result, project|
          parse_zoekt_search_result(result, project)
        end
      end

      def zoekt_search(query, num:, options:)
        start = Time.current

        body = {
          Q: query,
          Opts: {
            TotalMaxMatchCount: num,
            NumContextLines: 1
          }
        }

        # Safety net because Zoekt will match all projects if you provide
        # an empty array.
        raise "Not possible to search no projects" if options[:project_ids] == []

        body[:RepoIDs] = options[:project_ids] unless options[:project_ids] == :any

        base_url = ::Zoekt::Shard.first.search_base_url

        path = '/api/search'
        request_body = body.to_json
        response = ::Gitlab::HTTP.post(
          URI.join(base_url, path),
          headers: { "Content-Type" => "application/json" },
          body: request_body,
          allow_local_requests: true
        )

        unless response.success?
          logger.error(message: "Zoekt search failed", status: response.code, response: response.body)
        end

        ::Gitlab::Json.parse(response.body, symbolize_names: true)
      ensure
        add_request_details(start_time: start, path: path, body: request_body)
      end

      def add_request_details(start_time:, path:, body:)
        return unless ::Gitlab::SafeRequestStore.active?

        duration = (Time.current - start_time)

        ::Gitlab::Instrumentation::Zoekt.increment_request_count
        ::Gitlab::Instrumentation::Zoekt.add_duration(duration)

        ::Gitlab::Instrumentation::Zoekt.add_call_details(
          duration: duration,
          method: 'POST',
          path: path,
          body: body
        )
      end

      def zoekt_search_and_wrap(query, page: 1, per_page: 20, options: {}, preload_method: nil, &blk)
        search_result = zoekt_search(
          query,
          num: (per_page * page),
          options: options
        )

        if search_result[:Error]
          @blobs_count = 0
          @error = search_result[:Error]
          return Kaminari.paginate_array([])
        end

        total_count = search_result[:Result][:MatchCount]

        response = (search_result[:Result][:Files] || []).flat_map do |r|
          project_id = r[:Repository].to_i

          r[:LineMatches].map do |match|
            {
              project_id: project_id,
              content: [match[:Before], match[:Line], match[:After]].compact.map { |l| Base64.decode64(l) }.join("\n"),
              line: match[:LineNumber],
              path: r[:FileName]
            }
          end
        end

        items, total_count = yield_each_zoekt_search_result(response, preload_method, total_count, &blk)

        offset = (page - 1) * per_page
        Kaminari.paginate_array(items, total_count: total_count, limit: per_page, offset: offset)
      end

      def yield_each_zoekt_search_result(response, preload_method, total_count)
        project_ids = response.pluck(:project_id).uniq # rubocop:disable CodeReuse/ActiveRecord
        projects = Project.with_route.id_in(project_ids)
        projects = projects.public_send(preload_method) if preload_method # rubocop:disable GitlabSecurity/PublicSend
        projects = projects.index_by(&:id)

        items = response.map do |result|
          project_id = result[:project_id]
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

      def logger
        @logger ||= ::Zoekt::Logger.build
      end
    end
  end
end
