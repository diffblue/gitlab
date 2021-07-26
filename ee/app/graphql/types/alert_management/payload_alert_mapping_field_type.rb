# frozen_string_literal: true

module Types
  module AlertManagement
    class PayloadAlertMappingFieldType < BaseObject
      graphql_name 'AlertManagementPayloadAlertMappingField'
      description 'Parsed field (with its name) from an alert used for custom mappings'

      authorize :read_alert_management_alert

      field :field_name,
            ::Types::AlertManagement::PayloadAlertFieldNameEnum,
            null: true,
            description: 'A GitLab alert field name.'

      field :path,
            [::Types::AlertManagement::PayloadAlertFieldPathSegmentType],
            null: true,
            description: 'Path to value inside payload JSON.'

      field :label,
            GraphQL::Types::String,
            null: true,
            description: 'Human-readable label of the payload path.'

      field :type,
            ::Types::AlertManagement::PayloadAlertFieldTypeEnum,
            null: true,
            description: 'Type of the parsed value.'
    end
  end
end
