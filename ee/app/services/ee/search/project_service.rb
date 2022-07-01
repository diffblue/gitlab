# frozen_string_literal: true

module EE
  module Search
    module ProjectService
      extend ::Gitlab::Utils::Override
      include ::Search::Elasticsearchable

      SCOPES_THAT_SUPPORT_BRANCHES = %w(wiki_blobs commits blobs).freeze

      override :execute
      def execute
        return super if project.respond_to?(:archived?) && project.archived?
        return super unless use_elasticsearch? && use_default_branch?

        search = params[:search]
        order_by = params[:order_by]
        sort = params[:sort]
        filters = { confidential: params[:confidential], state: params[:state], language: params[:language] }

        if project.is_a?(Array)
          project_ids = Array(project).map(&:id)
          ::Gitlab::Elastic::SearchResults.new(
            current_user,
            search,
            project_ids,
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

      def elasticsearchable_scope
        project
      end
    end
  end
end
