# frozen_string_literal: true

module EE
  module Gitlab
    module ImportExport
      module Importer
        extend ::Gitlab::Utils::Override

        override :restorers

        def restorers
          return super unless project.gitlab_custom_project_template_import?

          super << custom_template_restorer
        end

        def custom_template_restorer
          ::Gitlab::ImportExport::Project::CustomTemplateRestorer.new(
            project: project,
            shared: shared,
            user: current_user
          )
        end
      end
    end
  end
end
