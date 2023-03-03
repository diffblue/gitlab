# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountEnterpriseUsersBasedOnDomainVerificationMetric < DatabaseMetric
          operation :count

          relation do
            UserDetail.enterprise_based_on_domain_verification
          end
        end
      end
    end
  end
end
