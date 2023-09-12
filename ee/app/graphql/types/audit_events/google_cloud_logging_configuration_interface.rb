# frozen_string_literal: true

module Types
  module AuditEvents
    module GoogleCloudLoggingConfigurationInterface
      include Types::BaseInterface

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

      field :name, GraphQL::Types::String,
        null: false,
        description: 'Name of the external destination to send audit events to.'
    end
  end
end
