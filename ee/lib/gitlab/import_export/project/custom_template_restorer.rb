# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class CustomTemplateRestorer
        include CustomTemplateRestorerHelper

        def initialize(project:, shared:, user:)
          @project = project
          @shared = shared
          @user = user
          set_source
        end

        def restore
          return true unless user_can_admin_source?
          return true if source_project.nil?
          return true unless project.gitlab_custom_project_template_import?

          [hooks_restorer, deploy_keys_restorer].all?(&:restore)
        end

        private

        attr_reader :project, :shared, :user, :source_project

        def set_source
          # It is ok to use ::Project.find because
          # we check later if user is source project owner
          # and import_data cannot be set by user via the import files
          source_project_id = project.import_data&.data&.fetch("template_project_id", nil)

          @source_project = ::Project.find_by_id(source_project_id) if source_project_id
        end

        def hooks_restorer
          ProjectHooksRestorer.new(project: project, shared: shared, user: user, source_project: source_project)
        end

        def deploy_keys_restorer
          DeployKeysRestorer.new(project: project, shared: shared, user: user, source_project: source_project)
        end
      end
    end
  end
end
