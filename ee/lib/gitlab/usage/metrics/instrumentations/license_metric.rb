# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class LicenseMetric < GenericMetric
          # Usage example
          #
          # In metric YAML defintion
          # instrumentation_class: LicenseMetric
          # options:
          #   attribute: md5
          # end

          ALLOWED_ATTRIBUTES = %w(add_ons
                                  daily_billable_users_count
                                  expires_at
                                  license_id
                                  plan
                                  sha256
                                  subscription_id
                                  starts_at
                                  trial?
                                  trial_ends_on
                                  user_count).freeze

          def initialize(metric_definition)
            super

            raise ArgumentError, "License options attribute are required" unless license_attribute.present?
            raise ArgumentError, "Attribute: #{license_attribute} it not allowed" unless license_attribute.in?(ALLOWED_ATTRIBUTES)
          end

          def value
            return ::License.trial_ends_on if license_attribute == "trial_ends_on"
            return ::License.current.restricted_user_count if license_attribute == "user_count"

            alt_usage_data(fallback: nil) do
              # license_attribute is checked in the constructor, so it's safe
              ::License.current.send(license_attribute)  # rubocop: disable GitlabSecurity/PublicSend
            end
          end

          private

          def license_attribute
            options[:attribute]
          end
        end
      end
    end
  end
end
