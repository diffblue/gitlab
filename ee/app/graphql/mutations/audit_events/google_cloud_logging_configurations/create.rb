# frozen_string_literal: true

module Mutations
  module AuditEvents
    module GoogleCloudLoggingConfigurations
      class Create < BaseMutation
        graphql_name 'GoogleCloudLoggingConfigurationCreate'

        authorize :admin_external_audit_events

        argument :group_path, GraphQL::Types::ID,
          required: true,
          description: 'Group path.'

        argument :google_project_id_name, GraphQL::Types::String,
          required: true,
          description: 'Google project ID.'

        argument :client_email, GraphQL::Types::String,
          required: true,
          description: 'Client email.'

        argument :log_id_name, GraphQL::Types::String,
          required: false,
          description: 'Log ID. (defaults to `audit_events`).',
          default_value: 'audit_events'

        argument :private_key, GraphQL::Types::String,
          required: true,
          description: 'Private key.'

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
