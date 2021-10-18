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

          ALLOWED_ATTRIBUTES = %i(md5
                                  id
                                  plan
                                  trial
                                  starts_at
                                  expires_at
                                  user_count
                                  trial_ends_on
                                  subscription_id).freeze

          def initialize(time_frame:, options: {})
            super

            raise ArgumentError, "License options attribute are required" unless license_attribute.present?
            raise ArgumentError, "attribute should one allowed" unless license_attribute.in?(ALLOWED_ATTRIBUTES)
          end

          def license_attribute
            options[:attribute]
          end

          def value
            alt_usage_data(fallback: -1) do
              ::Licese.current.send(license_attribute)
            end
          end
        end
      end
    end
  end
end
