# frozen_string_literal: true

module Types
  module AuditEvents
    class GoogleCloudLoggingConfigurationType < ::Types::BaseObject
      graphql_name 'GoogleCloudLoggingConfigurationType'
      description 'Stores Google Cloud Logging configurations associated with IAM service accounts,' \
                  'used for generating access tokens.'
      authorize :admin_external_audit_events

      field :group, ::Types::GroupType,
        null: false,
        description: 'Group the configuration belongs to.'

      field :id, GraphQL::Types::ID,
        null: false,
        description: 'ID of the configuration.'

      field :google_project_id_name, GraphQL::Types::String,
        null: false,
        description: 'Google project ID.'

      field :client_email, GraphQL::Types::String,
        null: false,
        description: 'Client email.'

      field :log_id_name, GraphQL::Types::String,
        null: false,
        description: 'Log ID.'

      field :private_key, GraphQL::Types::String,
        null: false,
        description: 'Private key.'
    end
  end
end
