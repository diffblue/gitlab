# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Status
        module Build
          module WaitingForApproval
            extend ActiveSupport::Concern

            def illustration
              {
                image: 'illustrations/manual_action.svg',
                size: 'svg-394',
                title: _('Waiting for approvals'),
                content: format(
                  _("This job deploys to the protected environment \"%{environment}\", which requires approvals. " \
                    "You can approve or reject the deployment on the environment details page."),
                  environment: subject.deployment&.environment&.name
                )
              }
            end

            def has_action?
              true
            end

            def action_icon
              nil
            end

            def action_title
              nil
            end

            def action_button_title
              _('View environment details page')
            end

            def action_path
              project_environment_path(subject.project, subject.deployment&.environment)
            end

            def action_method
              :get
            end

            class_methods do
              extend ::Gitlab::Utils::Override

              override :matches?
              def matches?(build, _user)
                build.waiting_for_deployment_approval?
              end
            end
          end
        end
      end
    end
  end
end
