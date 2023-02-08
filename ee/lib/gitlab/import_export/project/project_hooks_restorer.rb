# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class ProjectHooksRestorer
        def initialize(project:, shared:, user:, source:)
          @project = project
          @shared = shared
          @user = user
          @source = source
        end

        def restore
          check_user_authorization

          hooks_duplicated = duplicate_source_hooks

          return true if hooks_duplicated

          report_failure

          false
        end

        private

        def check_user_authorization
          return if user_can_admin_source?

          err = StandardError.new "Unauthorized service"
          Gitlab::Import::Logger.warn(
            message: "User tried to access unauthorized service",
            username: @user.username,
            user_id: @user.id,
            service: self.class.name,
            error: err.message
          )

          raise err
        end

        def user_can_admin_source?
          @user.can_admin_all_resources? || @user.can?(:owner_access, @source)
        end

        def duplicate_source_hooks
          result = []

          @source.hooks.order_by(created_at: :asc).find_each do |source_hook|
            target_hook = duplicate_hook(source_hook)

            result << target_hook.save
          end

          result.all?
        end

        def duplicate_hook(source_hook)
          target_hook = source_hook.dup
          target_hook.project_id = @project.id

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
          Gitlab::Import::ImportFailureService.track(
            project_id: @project.id,
            error_source: self.class.name,
            exception: StandardError.new("Could not duplicate all project hooks from custom template Project"),
            fail_import: false
          )
        end
      end
    end
  end
end
