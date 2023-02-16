# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      module CustomTemplateRestorerHelper
        private

        def user_can_admin_source?
          user.can_admin_all_resources? || user.can?(:owner_access, source_project)
        end

        def check_user_authorization
          return if user_can_admin_source?

          err = StandardError.new "Unauthorized service"
          Gitlab::Import::Logger.warn(
            message: "User tried to access unauthorized service",
            username: user.username,
            user_id: user.id,
            service: self.class.name,
            error: err.message
          )

          raise err
        end

        def report_failure_for(related_model)
          humanized_model_name = related_model.name.underscore.downcase.pluralize.tr('_', ' ')
          exception_message = "Could not duplicate all #{humanized_model_name} from custom template Project"

          Gitlab::Import::ImportFailureService.track(
            project_id: project.id,
            error_source: self.class.name,
            exception: StandardError.new(exception_message),
            fail_import: false
          )
        end
      end
    end
  end
end
