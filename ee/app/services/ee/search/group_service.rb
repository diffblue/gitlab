# frozen_string_literal: true

module EE
  module Search
    module GroupService
      extend ::Gitlab::Utils::Override
      include ::Search::ZoektSearchable

      override :elasticsearchable_scope
      def elasticsearchable_scope
        group unless global_elasticsearchable_scope?
      end

      override :zoekt_searchable_scope
      def zoekt_searchable_scope
        group
      end

      override :elastic_global
      def elastic_global
        false
      end

      override :elastic_projects
      def elastic_projects
        @elastic_projects ||= projects.pluck_primary_key
      end

      override :zoekt_projects
      def zoekt_projects
        @zoekt_projects ||= projects.pluck_primary_key
      end

      override :execute
      def execute
        return zoekt_search_results if use_zoekt?
        return super unless use_elasticsearch?

        ::Gitlab::Elastic::GroupSearchResults.new(
          current_user,
          params[:search],
          elastic_projects,
          group: group,
          public_and_internal_projects: elastic_global,
          order_by: params[:order_by],
          sort: params[:sort],
          filters: { confidential: params[:confidential], state: params[:state], language: params[:language] }
        )
      end

      override :allowed_scopes
      def allowed_scopes
        return super unless group.licensed_feature_available?(:epics)

        strong_memoize(:ee_group_allowed_scopes) do
          super + %w(epics)
        end
      end
    end
  end
end
