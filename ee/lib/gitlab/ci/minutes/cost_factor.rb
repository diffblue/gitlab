# frozen_string_literal: true

module Gitlab
  module Ci
    module Minutes
      class CostFactor
        DISABLED = 0.0
        PUBLIC_OPEN_SOURCE = 0.5

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

        # Each runners has a public and private cost factor
        # Pass the project to `for_project` to get a projects cost factor
        # based on the runner cost factors and project visibility level
        def for_project(project)
          return DISABLED unless @runner_matcher.instance_type?
          return DISABLED unless project.ci_minutes_usage.limit_enabled?

          cost_factors = [for_visibility(project.visibility_level)]
          cost_factors << PUBLIC_OPEN_SOURCE if public_open_source?(project)

          # Exceptions to the cost per runner(for_visibility) are designed
          # to be discounts so take the lowest value
          cost_factors.min
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

        def public_open_source?(project)
          Feature.enabled?(:ci_new_public_oss_cost_factor, project) &&
            project.public? &&
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
