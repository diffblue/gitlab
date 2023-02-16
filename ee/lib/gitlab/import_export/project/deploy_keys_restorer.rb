# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class DeployKeysRestorer
        include CustomTemplateRestorerHelper

        def initialize(project:, shared:, user:, source_project:)
          @project = project
          @shared = shared
          @user = user
          @source_project = source_project
        end

        def restore
          check_user_authorization

          project_keys_duplicated = duplicate_project_keys

          report_failure unless project_keys_duplicated

          true
        end

        private

        attr_reader :project, :shared, :user, :source_project

        def duplicate_project_keys
          result = []

          source_project.deploy_keys_projects.find_each do |source_project_key|
            deploy_key = source_project_key.deploy_key

            target_project_key = ::DeployKeysProject.new(
              deploy_key: deploy_key,
              project: project,
              can_push: source_project_key.can_push
            )

            result << target_project_key.save
          end

          result.all?
        end

        def report_failure
          report_failure_for(::DeployKeysProject)
        end
      end
    end
  end
end
