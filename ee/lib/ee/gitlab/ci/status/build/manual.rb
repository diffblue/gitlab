# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Status
        module Build
          module Manual
            extend ActiveSupport::Concern
            extend ::Gitlab::Utils::Override

            private

            override :generic_permission_failure_message
            def generic_permission_failure_message
              if subject.persisted_environment.try(:protected_from?, user)
                _("This deployment job does not run automatically and must be started manually, but you do not have access to this job's protected environment. The job can only be started by a project member allowed to deploy to the environment.")
              else
                super
              end
            end
          end
        end
      end
    end
  end
end
