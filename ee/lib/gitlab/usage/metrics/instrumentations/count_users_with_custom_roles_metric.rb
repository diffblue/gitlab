# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUsersWithCustomRolesMetric < DatabaseMetric
          operation :distinct_count, column: :user_id

          relation do
            Member.where.not(member_role: nil)
          end
        end
      end
    end
  end
end
