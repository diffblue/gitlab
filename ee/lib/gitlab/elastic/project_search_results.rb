# frozen_string_literal: true

module Gitlab
  module Elastic
    # Always prefer to use the full class namespace when specifying a
    # superclass inside a module, because autoloading can occur in a
    # different order between execution environments.
    class ProjectSearchResults < Gitlab::Elastic::SearchResults
      attr_reader :project, :repository_ref, :filters

      def initialize(current_user, query, project:, repository_ref: nil, order_by: nil, sort: nil, filters: {})
        @project = project
        @repository_ref = repository_ref.presence || project.default_branch

        super(current_user, query, [project.id], public_and_internal_projects: false, order_by: order_by, sort: sort, filters: filters)
      end

      private

      def blobs(page: 1, per_page: DEFAULT_PER_PAGE, count_only: false, preload_method: nil)
        return Kaminari.paginate_array([]) unless Ability.allowed?(@current_user, :download_code, project)
        return Kaminari.paginate_array([]) if project.empty_repo? || query.blank?

        strong_memoize(memoize_key(:blobs, count_only: count_only)) do
          project.repository.__elasticsearch__.elastic_search_as_found_blob(
            query,
            page: (page || 1).to_i,
            per: per_page,
            options: { count_only: count_only },
            preload_method: preload_method
          )
        end
      end

      def wiki_blobs(page: 1, per_page: DEFAULT_PER_PAGE, count_only: false)
        return Kaminari.paginate_array([]) unless Ability.allowed?(@current_user, :read_wiki, project)
        return Kaminari.paginate_array([]) unless project.wiki_enabled? && !project.wiki.empty? && query.present?

        strong_memoize(memoize_key(:wiki_blobs, count_only: count_only)) do
          project.wiki.__elasticsearch__.elastic_search_as_wiki_page(
            query,
            page: (page || 1).to_i,
            per: per_page,
            options: { count_only: count_only }
          )
        end
      end

      def notes(count_only: false)
        strong_memoize(memoize_key(:notes, count_only: count_only)) do
          opt = {
            project_ids: limit_project_ids,
            current_user: @current_user,
            public_and_internal_projects: @public_and_internal_projects,
            count_only: count_only
          }

          Note.elastic_search(query, options: opt)
        end
      end

      def commits(page: 1, per_page: DEFAULT_PER_PAGE, preload_method: nil, count_only: false)
        return Kaminari.paginate_array([]) unless Ability.allowed?(@current_user, :download_code, project)
        return Kaminari.paginate_array([]) if project.empty_repo? || query.blank?

        strong_memoize(memoize_key(:commits, count_only: count_only)) do
          project.repository.find_commits_by_message_with_elastic(
            query,
            page: (page || 1).to_i,
            per_page: per_page,
            preload_method: preload_method,
            options: { count_only: count_only }
          )
        end
      end
    end
  end
end
