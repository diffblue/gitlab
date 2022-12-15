# frozen_string_literal: true

module EE
  module API
    module Entities
      class DependencyListExport < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers

        expose :id
        expose :finished?, as: :has_finished

        expose :self do |export|
          expose_url api_v4_projects_dependency_list_exports_path(id: export.project.id, export_id: export.id)
        end
        expose :download do |export|
          expose_url api_v4_projects_dependency_list_exports_download_path(id: export.project.id, export_id: export.id)
        end
      end
    end
  end
end
