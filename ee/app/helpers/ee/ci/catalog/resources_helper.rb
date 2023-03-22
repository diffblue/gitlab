# frozen_string_literal: true

module EE
  module Ci
    module Catalog
      module ResourcesHelper
        include ChecksCollaboration
        extend ::Gitlab::Utils::Override

        override :can_view_private_catalog?
        def can_view_private_catalog?(project)
          ::Feature.enabled?(:ci_private_catalog_beta, project) &&
            project.licensed_feature_available?(:ci_private_catalog) &&
            can_collaborate_with_project?(project)
        end

        override :js_ci_catalog_data?
        def js_ci_catalog_data(project)
          return super unless can_view_private_catalog?(project)

          super.merge(
            "ci_catalog_path" => project_ci_catalog_resources_path(project)
          )
        end
      end
    end
  end
end
