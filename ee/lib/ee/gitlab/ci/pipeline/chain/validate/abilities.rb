# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Pipeline
        module Chain
          module Validate
            module Abilities
              extend ::Gitlab::Utils::Override

              override :perform!
              def perform!
                # We check for `builds_enabled?` here so that this error does
                # not get produced before the "pipelines are disabled" error.
                if project.builds_enabled? &&
                    (command.allow_mirror_update && !project.mirror_trigger_builds?)
                  return error('Pipeline is disabled for mirror updates')
                end

                super
              end

              override :builds_enabled?
              def builds_enabled?
                project.builds_enabled? || pipeline.ignores_ci_settings?
              end

              override :allowed_to_write_ref?
              def allowed_to_write_ref?
                return true if current_user&.security_policy_bot? && pipeline.ignores_ci_settings?

                super
              end
            end
          end
        end
      end
    end
  end
end
