# frozen_string_literal: true

# Attribute mapping for alerts via alerting integration.
module EE
  module Gitlab
    module AlertManagement
      module Payload
        module Mappable
          extend ::Gitlab::Utils::Override
          include ::Gitlab::Utils::StrongMemoize

          {
            title: 'title',
            description: 'description',
            starts_at: 'start_time',
            ends_at: 'end_time',
            service: 'service',
            monitoring_tool: 'monitoring_tool',
            hosts: 'hosts',
            severity_raw: 'severity',
            environment_name: 'gitlab_environment_name',
            plain_gitlab_fingerprint: 'fingerprint',
            source: 'monitoring_tool'
          }.each do |method_name, attribute|
            override method_name

            define_method(method_name) do
              next super() unless custom_mapping.present?

              value = custom_mapping_value(attribute)
              type = custom_mapping_type(attribute)
              value = parse_value(value, type) if value

              value.presence || super()
            end

            strong_memoize_attr method_name
          end
          private :severity_raw
          private :plain_gitlab_fingerprint

          private

          def custom_mapping
            return unless ::Gitlab::AlertManagement.custom_mapping_available?(project)
            return unless integration&.active?

            integration.payload_attribute_mapping
          end
          strong_memoize_attr :custom_mapping

          def custom_mapping_value(attribute_name)
            custom_mapping_path = custom_mapping.dig(attribute_name, 'path')

            payload&.dig(*custom_mapping_path) if custom_mapping_path
          end

          def custom_mapping_type(attribute_name)
            :time if custom_mapping.dig(attribute_name, 'type') == 'datetime'
          end
        end
      end
    end
  end
end
