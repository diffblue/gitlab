# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Pipeline
        module Chain
          module Limit
            module Size
              extend ::Gitlab::Utils::Override
              include ::Gitlab::Ci::Pipeline::Chain::Helpers

              attr_reader :limit
              private :limit

              def initialize(*)
                super

                @limit = Pipeline::Quota::Size
                  .new(project.namespace, pipeline, command)
              end

              override :perform!
              def perform!
                if limit.exceeded?
                  limit.log_error!(log_attrs)
                  error(limit.message, drop_reason: :size_limit_exceeded)
                elsif limit.log_exceeded_limit?
                  limit.log_error!(log_attrs)
                end
              end

              override :break?
              def break?
                limit.exceeded?
              end

              private

              def log_attrs
                {
                  jobs_count: pipeline.statuses.count,
                  pipeline_source: pipeline.source,
                  plan: project.actual_plan_name,
                  project_id: project.id,
                  project_full_path: project.full_path
                }
              end
            end
          end
        end
      end
    end
  end
end
