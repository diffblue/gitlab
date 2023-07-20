# frozen_string_literal: true

module EE
  module Search
    module ProjectService
      extend ::Gitlab::Utils::Override
      include ::Search::Elasticsearchable
      include ::Search::ZoektSearchable

      SCOPES_THAT_SUPPORT_BRANCHES = %w(wiki_blobs commits blobs).freeze

      override :execute
      def execute
        return super if project.respond_to?(:archived?) && project.archived?
        return zoekt_search_results if use_zoekt? && use_default_branch?
        return super unless use_elasticsearch? && use_default_branch?

        search = params[:search]
        order_by = params[:order_by]
        sort = params[:sort]

        if project.is_a?(Array)
          project_id_root_ancestor_id_hash = project.to_h { |p| [p.id, p.root_ancestor.id] }
          project_ids = project_id_root_ancestor_id_hash.keys
          root_ancestor_ids = project_id_root_ancestor_id_hash.values
          ::Gitlab::Elastic::SearchResults.new(
            current_user,
            search,
            project_ids,
            root_ancestor_ids: root_ancestor_ids,
            public_and_internal_projects: false,
            order_by: order_by,
            sort: sort,
            filters: filters
          )
        else
          ::Gitlab::Elastic::ProjectSearchResults.new(
            current_user,
            search,
            project: project,
            root_ancestor_ids: [project.root_ancestor.id],
            repository_ref: repository_ref,
            order_by: order_by,
            sort: sort,
            filters: filters
          )
        end
      end

      def repository_ref
        params[:repository_ref]
      end

      def use_default_branch?
        return true if repository_ref.blank?
        return true unless SCOPES_THAT_SUPPORT_BRANCHES.include?(scope)

        project.root_ref?(repository_ref)
      end

      override :elasticsearchable_scope
      def elasticsearchable_scope
        project unless global_elasticsearchable_scope?
      end

      override :zoekt_searchable_scope
      def zoekt_searchable_scope
        project
      end

      override :zoekt_projects
      def zoekt_projects
        @zoekt_projects ||= Array(project).map(&:id)
      end
    end
  end
end
