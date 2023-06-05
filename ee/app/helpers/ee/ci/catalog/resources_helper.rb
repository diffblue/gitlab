# frozen_string_literal: true

module EE
  module Ci
    module Catalog
      module ResourcesHelper
        extend ::Gitlab::Utils::Override

        override :can_add_catalog_resource?
        def can_add_catalog_resource?(project)
          super || can?(current_user, :add_catalog_resource, project)
        end

        override :can_view_namespace_catalog?
        def can_view_namespace_catalog?(project)
          super || can?(current_user, :read_namespace_catalog, project)
        end

        override :js_ci_catalog_data
        def js_ci_catalog_data(project)
          return super unless can_view_namespace_catalog?(project)

          super.merge(
            "ci_catalog_path" => project_ci_catalog_resources_path(project),
            "project_full_path" => project.full_path
          )
        end
      end
    end
  end
end
