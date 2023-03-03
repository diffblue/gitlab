# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountEnterpriseUsersCreatedViaSamlOrScimMetric < DatabaseMetric
          operation :count

          relation do
            UserDetail.enterprise_created_via_saml_or_scim
          end
        end
      end
    end
  end
end
