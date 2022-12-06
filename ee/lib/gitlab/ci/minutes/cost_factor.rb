# frozen_string_literal: true

module Gitlab
  module Ci
    module Minutes
      class CostFactor
        DISABLED = 0.0
        PUBLIC_OPEN_SOURCE_PLAN = 0.5
        OPEN_SOURCE_CONTRIBUTION = 0.008

        def initialize(runner_matcher)
          ensure_runner_matcher_instance(runner_matcher)

          @runner_matcher = runner_matcher
        end

        def enabled?(project)
          for_project(project) > 0
        end

        def disabled?(project)
          !enabled?(project)
        end

        # Each runner has a public and private cost factor
        # Pass the project to `for_project` to get a projects cost factor
        # based on the runner cost factors by project visibility level
        def for_project(project)
          return DISABLED unless @runner_matcher.instance_type?
          return DISABLED unless project.ci_minutes_usage.quota_enabled?

          runner_cost_factor = cost_factor_for_runner(project)
          apply_discount(project, runner_cost_factor)
        end

        private

        def cost_factor_for_runner(project)
          if project.public?
            @runner_matcher.public_projects_minutes_cost_factor
          else
            @runner_matcher.private_projects_minutes_cost_factor
          end
        end

        # Exceptions to the cost per runner are designed
        # to be discounts so take the lowest value
        def apply_discount(project, runner_cost_factor)
          cost_factors = [runner_cost_factor]

          if project.public?
            cost_factors << PUBLIC_OPEN_SOURCE_PLAN if open_source_plan?(project)
            cost_factors << OPEN_SOURCE_CONTRIBUTION if open_source_project?(project)
          end

          cost_factors.min
        end

        def open_source_project?(project)
          fork_source = project&.fork_source

          fork_source&.public? && open_source_plan?(fork_source)
        end

        def open_source_plan?(project)
          project.actual_plan.open_source?
        end

        def ensure_runner_matcher_instance(runner_matcher)
          unless runner_matcher.is_a?(Matching::RunnerMatcher)
            raise ArgumentError, 'only Matching::RunnerMatcher objects allowed'
          end
        end
      end
    end
  end
end
