# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Pipeline
        module Chain
          module Validate
            module AfterConfig
              extend ::Gitlab::Utils::Override

              override :perform!
              def perform!
                if current_user && !current_user.has_required_credit_card_to_run_pipelines?(project)
                  ::Gitlab::AppLogger.info(
                    message: 'Credit card required to be on file in order to create a pipeline',
                    project_path: project.full_path,
                    user_id: current_user.id,
                    plan: project.root_namespace.actual_plan_name
                  )

                  return error('Credit card required to be on file in order to create a pipeline', drop_reason: :user_not_verified)
                end

                super
              end
            end
          end
        end
      end
    end
  end
end
