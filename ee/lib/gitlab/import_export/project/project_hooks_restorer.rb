# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class ProjectHooksRestorer
        include CustomTemplateRestorerHelper

        def initialize(project:, shared:, user:, source_project:)
          @project = project
          @shared = shared
          @user = user
          @source_project = source_project
        end

        def restore
          check_user_authorization

          hooks_duplicated = duplicate_source_hooks

          report_failure unless hooks_duplicated

          true
        end

        private

        attr_reader :project, :shared, :user, :source_project

        def duplicate_source_hooks
          result = []

          source_project.hooks.order_by(created_at: :asc).find_each do |source_hook|
            target_hook = duplicate_hook(source_hook)

            result << target_hook.save
          end

          result.all?
        end

        def duplicate_hook(source_hook)
          target_hook = source_hook.dup
          target_hook.project_id = project.id

          # clean encrypted fields
          target_hook.encrypted_url = nil
          target_hook.encrypted_url_variables = nil
          target_hook.encrypted_token = nil
          target_hook.encrypted_url_iv = nil
          target_hook.encrypted_url_variables_iv = nil
          target_hook.encrypted_token_iv = nil

          target_hook.url = source_hook.url
          target_hook.url_variables = source_hook.url_variables
          target_hook.token = source_hook.token

          target_hook
        end

        def report_failure
          report_failure_for(::ProjectHook)
        end
      end
    end
  end
end
