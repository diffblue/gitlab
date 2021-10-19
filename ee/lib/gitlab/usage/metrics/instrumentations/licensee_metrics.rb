# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class LicenseeMetrics < ::Gitlab::Usage::Metrics::Instrumentations::GenericMetric
          value do
            {
              "Name" => ::License.current.licensee_name,
              "Company" => ::License.current.licensee_company,
              "Email" => ::License.current.licensee_email
            }
          end
        end
      end
    end
  end
end
