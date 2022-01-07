# frozen_string_literal: true

module Gitlab
  module Ci
    module Minutes
      class CostFactor
        DISABLED = 0.0
        STANDARD = 1.0
        OPEN_SOURCE = 0.008
        NEW_NAMESPACE_PUBLIC_PROJECT = 0.008

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

        def for_project(project)
          return DISABLED unless @runner_matcher.instance_type?
          return DISABLED unless project.ci_minutes_quota.enabled?

          runner_cost_factor = for_visibility(project.visibility_level)

          if runner_cost_factor == DISABLED && project.force_cost_factor?
            # Once visibility level cost factors are consolidated into a single
            # cost factor, this condition can be removed.
            # https://gitlab.com/gitlab-org/gitlab/-/issues/243722
            NEW_NAMESPACE_PUBLIC_PROJECT
          elsif runner_cost_factor == STANDARD && project.actual_plan.open_source?
            OPEN_SOURCE
          else
            runner_cost_factor
          end
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

        def ensure_runner_matcher_instance(runner_matcher)
          unless runner_matcher.is_a?(Matching::RunnerMatcher)
            raise ArgumentError, 'only Matching::RunnerMatcher objects allowed'
          end
        end
      end
    end
  end
end
