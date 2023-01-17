# frozen_string_literal: true

module Gitlab
  module Elastic
    # Always prefer to use the full class namespace when specifying a
    # superclass inside a module, because autoloading can occur in a
    # different order between execution environments.
    class ProjectSearchResults < Gitlab::Elastic::SearchResults
      extend Gitlab::Utils::Override

      attr_reader :project, :repository_ref, :filters

      def initialize(current_user, query, project:, repository_ref: nil, order_by: nil, sort: nil, filters: {})
        @project = project
        @repository_ref = repository_ref.presence || project.default_branch

        super(current_user, query, [project.id], public_and_internal_projects: false, order_by: order_by, sort: sort, filters: filters)
      end

      private

      def blobs(page: 1, per_page: DEFAULT_PER_PAGE, count_only: false, preload_method: nil)
        return Kaminari.paginate_array([]) if project.empty_repo? || query.blank?
        return Kaminari.paginate_array([]) unless Ability.allowed?(@current_user, :read_code, project)

        strong_memoize(memoize_key(:blobs, count_only: count_only)) do
          project.repository.__elasticsearch__.elastic_search_as_found_blob(
            query,
            page: (page || 1).to_i,
            per: per_page,
            options: base_options.merge(count_only: count_only).merge(filters.slice(:language)),
            preload_method: preload_method
          )
        end
      end

      def wiki_blobs(page: 1, per_page: DEFAULT_PER_PAGE, count_only: false)
        return Kaminari.paginate_array([]) unless project.wiki_enabled? && !project.wiki.empty? && query.present?
        return Kaminari.paginate_array([]) unless Ability.allowed?(@current_user, :read_wiki, project)

        strong_memoize(memoize_key(:wiki_blobs, count_only: count_only)) do
          project.wiki.__elasticsearch__.elastic_search_as_wiki_page(
            query,
            page: (page || 1).to_i,
            per: per_page,
            options: base_options.merge(count_only: count_only)
          )
        end
      end

      def notes(count_only: false)
        strong_memoize(memoize_key(:notes, count_only: count_only)) do
          Note.elastic_search(query, options: base_options.merge(count_only: count_only))
        end
      end

      def commits(page: 1, per_page: DEFAULT_PER_PAGE, preload_method: nil, count_only: false)
        return Kaminari.paginate_array([]) if project.empty_repo? || query.blank?
        return Kaminari.paginate_array([]) unless Ability.allowed?(@current_user, :read_code, project)

        strong_memoize(memoize_key(:commits, count_only: count_only)) do
          project.repository.find_commits_by_message_with_elastic(
            query,
            page: (page || 1).to_i,
            per_page: per_page,
            preload_method: preload_method,
            options: base_options.merge(count_only: count_only)
          )
        end
      end

      def blob_aggregations
        return [] if project.empty_repo? || query.blank?
        return [] unless Ability.allowed?(@current_user, :read_code, project)

        strong_memoize(:blob_aggregations) do
          project.repository.__elasticsearch__.blob_aggregations(query, base_options)
        end
      end

      override :scope_options
      def scope_options(scope)
        case scope
        when :users
          super.merge(project_id: project.id)
        else
          super
        end
      end
    end
  end
end
