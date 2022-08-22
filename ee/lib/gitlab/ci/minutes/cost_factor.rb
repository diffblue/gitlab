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
          return DISABLED unless project.ci_minutes_usage.limit_enabled?

          runner_cost_factor = for_visibility(project.visibility_level)
          apply_discount(project, runner_cost_factor)
        end

        # This method SHOULD NOT BE USED by new code. It is currently depended
        # on by `BuildQueueService`. That dependency will be removed by
        # https://gitlab.com/groups/gitlab-org/-/epics/5909, and this method
        # should be made private at that time. Please use #for_project instead.
        def for_visibility(visibility_level)
          return 0.0 unless @runner_matcher.instance_type?

          case visibility_level
          when ::Gitlab::VisibilityLevel::PUBLIC
            @runner_matcher.public_projects_minutes_cost_factor
          when ::Gitlab::VisibilityLevel::PRIVATE, ::Gitlab::VisibilityLevel::INTERNAL
            @runner_matcher.private_projects_minutes_cost_factor
          else
            raise ArgumentError, 'Invalid visibility level'
          end
        end

        private

        # Exceptions to the cost per runner are designed
        # to be discounts so take the lowest value
        def apply_discount(project, runner_cost_factor)
          cost_factors = [runner_cost_factor]

          if project.public?
            cost_factors << PUBLIC_OPEN_SOURCE_PLAN if open_source_plan?(project)
            cost_factors << OPEN_SOURCE_CONTRIBUTION if public_fork_source?(project)
          end

          cost_factors.min
        end

        def public_fork_source?(project)
          Feature.enabled?(:ci_forked_source_public_cost_factor, project) &&
            project&.fork_source&.public?
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
