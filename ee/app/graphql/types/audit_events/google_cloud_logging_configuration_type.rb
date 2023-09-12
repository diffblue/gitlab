# frozen_string_literal: true

module Types
  module AuditEvents
    class GoogleCloudLoggingConfigurationType < ::Types::BaseObject
      graphql_name 'GoogleCloudLoggingConfigurationType'
      description 'Stores Google Cloud Logging configurations associated with IAM service accounts,' \
                  'used for generating access tokens.'
      authorize :admin_external_audit_events

      implements GoogleCloudLoggingConfigurationInterface

      field :group, ::Types::GroupType,
        null: false,
        description: 'Group the configuration belongs to.'
    end
  end
end
