# frozen_string_literal: true

module EE
  module BuildDetailEntity
    extend ActiveSupport::Concern

    prepended do
      expose :runners do
        expose :quota, if: ->(build, _) {
                             project.shared_runners_minutes_limit_enabled? &&
                               can?(current_user, :read_ci_minutes_limited_summary, build)
                           } do
          expose :used do |runner|
            project.ci_minutes_usage.total_minutes_used
          end

          expose :limit do |runner|
            project.ci_minutes_usage.quota.total
          end
        end
      end
    end
  end
end
