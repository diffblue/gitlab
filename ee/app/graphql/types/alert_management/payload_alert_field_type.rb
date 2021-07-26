# frozen_string_literal: true

module Types
  module AlertManagement
    class PayloadAlertFieldType < BaseObject
      graphql_name 'AlertManagementPayloadAlertField'
      description 'Parsed field from an alert used for custom mappings'

      authorize :read_alert_management_alert

      field :path,
            [Types::AlertManagement::PayloadAlertFieldPathSegmentType],
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
