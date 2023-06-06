# frozen_string_literal: true

module Mutations
  module AuditEvents
    module GoogleCloudLoggingConfigurations
      class Create < Base
        graphql_name 'GoogleCloudLoggingConfigurationCreate'

        authorize :admin_external_audit_events

        argument :group_path, GraphQL::Types::ID,
          required: true,
          description: 'Group path.'

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
        field :google_cloud_logging_configuration, ::Types::AuditEvents::GoogleCloudLoggingConfigurationType,
          null: true,
          description: 'configuration created.'

        def resolve(group_path:, google_project_id_name:, client_email:, private_key:, log_id_name: nil)
          group = authorized_find!(group_path)
          config_attributes = {
            group: group,
            google_project_id_name: google_project_id_name,
            client_email: client_email,
            private_key: private_key
          }

          config_attributes[:log_id_name] = log_id_name if log_id_name.present?

          config = ::AuditEvents::GoogleCloudLoggingConfiguration.new(config_attributes)

          if config.save
            audit(config, action: :created)

            { google_cloud_logging_configuration: config, errors: [] }
          else
            { google_cloud_logging_configuration: nil, errors: Array(config.errors) }
          end
        end

        private

        def find_object(group_path)
          ::Group.find_by_full_path(group_path)
        end
      end
    end
  end
end
