# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Instance
      module GoogleCloudLoggingConfigurations
        class Create < Base
          graphql_name 'InstanceGoogleCloudLoggingConfigurationCreate'

          argument :name, GraphQL::Types::String,
            required: false,
            description: 'Destination name.'

          argument :google_project_id_name, GraphQL::Types::String,
            required: true,
            description: 'Unique identifier of the Google Cloud project ' \
                         'to which the logging configuration belongs.'

          argument :client_email, GraphQL::Types::String,
            required: true,
            description: 'Email address associated with the service account ' \
                         'that will be used to authenticate and interact with the ' \
                         'Google Cloud Logging service. This is part of the IAM credentials.'

          argument :log_id_name, GraphQL::Types::String,
            required: false,
            description: 'Unique identifier used to distinguish and manage ' \
                         'different logs within the same Google Cloud project.' \
                         '(defaults to `audit_events`).',
            default_value: 'audit_events'

          argument :private_key, GraphQL::Types::String,
            required: true,
            description: 'Private Key associated with the service account. This key ' \
                         'is used to authenticate the service account and authorize it ' \
                         'to interact with the Google Cloud Logging service.'

          field :instance_google_cloud_logging_configuration,
            ::Types::AuditEvents::Instance::GoogleCloudLoggingConfigurationType,
            null: true,
            description: 'configuration created.'

          def resolve(google_project_id_name:, client_email:, private_key:, log_id_name: nil, name: nil)
            config_attributes = {
              google_project_id_name: google_project_id_name,
              client_email: client_email,
              private_key: private_key,
              name: name
            }

            config_attributes[:log_id_name] = log_id_name if log_id_name.present?

            config = ::AuditEvents::Instance::GoogleCloudLoggingConfiguration.new(config_attributes)

            if config.save
              audit(config, action: :created)

              { instance_google_cloud_logging_configuration: config, errors: [] }
            else
              { instance_google_cloud_logging_configuration: nil, errors: Array(config.errors) }
            end
          end
        end
      end
    end
  end
end
