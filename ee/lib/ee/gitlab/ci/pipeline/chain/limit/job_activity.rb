# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Pipeline
        module Chain
          module Limit
            module JobActivity
              extend ::Gitlab::Utils::Override
              include ::Gitlab::Ci::Pipeline::Chain::Helpers
              include ::Gitlab::OptimisticLocking

              attr_reader :limit
              private :limit

              def initialize(*)
                super

                @limit = Pipeline::Quota::JobActivity
                  .new(project.namespace, pipeline.project)
              end

              override :perform!
              def perform!
                # We've already run Chain::Limit::ActiveJobs if FF is enabled.
                return if command.limit_active_jobs_early?

                return unless limit.exceeded?

                retry_optimistic_lock(pipeline, name: 'ci_pipeline_chain_limit_job_activity') do
                  pipeline.drop!(:job_activity_limit_exceeded)
                  limit.log_error!(project_id: project.id, plan: project.actual_plan_name)
                end
              end

              override :break?
              def break?
                return false if command.limit_active_jobs_early?

                limit.exceeded?
              end
            end
          end
        end
      end
    end
  end
end
