# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Matching
        module RunnerMatcher
          include ::Gitlab::Utils::StrongMemoize

          def matches_quota?(build_matcher)
            cost_factor_disabled?(build_matcher) || !minutes_used_up?(build_matcher)
          end

          private

          def cost_factor_disabled?(build_matcher)
            cost_factor.disabled?(build_matcher.project)
          end

          def cost_factor
            strong_memoize(:cost_factor) do
              ::Gitlab::Ci::Minutes::CostFactor.new(self)
            end
          end

          def minutes_used_up?(build_matcher)
            build_matcher
              .project
              .ci_minutes_usage
              .minutes_used_up?
          end
        end
      end
    end
  end
end
