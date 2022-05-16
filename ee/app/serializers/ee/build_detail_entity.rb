# frozen_string_literal: true

module EE
  module BuildDetailEntity
    extend ActiveSupport::Concern

    prepended do
      expose :runners do
        expose :quota, if: -> (*) { project.shared_runners_minutes_limit_enabled? } do
          expose :used do |runner|
            project.ci_minutes_usage.total_minutes_used
          end

          expose :limit do |runner|
            project.ci_minutes_usage.limit.total
          end
        end
      end
    end
  end
end
