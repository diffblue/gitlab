# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountMemberRolesMetric < DatabaseMetric
          operation :count

          relation do
            MemberRole.all
          end
        end
      end
    end
  end
end
