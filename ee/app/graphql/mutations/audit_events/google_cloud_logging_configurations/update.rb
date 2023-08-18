# frozen_string_literal: true

module Mutations
  module AuditEvents
    module GoogleCloudLoggingConfigurations
      class Update < Base
        graphql_name 'GoogleCloudLoggingConfigurationUpdate'

        include ::Audit::Changes

        UPDATE_EVENT_NAME = 'google_cloud_logging_configuration_updated'
        AUDIT_EVENT_COLUMNS = [:google_project_id_name, :client_email, :private_key, :log_id_name, :name].freeze

        authorize :admin_external_audit_events

        argument :id, ::Types::GlobalIDType[::AuditEvents::GoogleCloudLoggingConfiguration],
          required: true,
          description: 'ID of the google Cloud configuration to update.'

        argument :name, GraphQL::Types::String,
          required: false,
          description: 'Destination name.'

        argument :google_project_id_name, GraphQL::Types::String,
          required: false,
          description: 'Unique identifier of the Google Cloud project ' \
                       'to which the logging configuration belongs.'

        argument :client_email, GraphQL::Types::String,
          required: false,
          description: 'Email address associated with the service account ' \
                       'that will be used to authenticate and interact with the ' \
                       'Google Cloud Logging service. This is part of the IAM credentials.'

        argument :log_id_name, GraphQL::Types::String,
          required: false,
          description: 'Unique identifier used to distinguish and manage ' \
                       'different logs within the same Google Cloud project.'

        argument :private_key, GraphQL::Types::String,
          required: false,
          description: 'Private Key associated with the service account. This key ' \
                       'is used to authenticate the service account and authorize it ' \
                       'to interact with the Google Cloud Logging service.'

        field :google_cloud_logging_configuration, ::Types::AuditEvents::GoogleCloudLoggingConfigurationType,
          null: true,
          description: 'configuration updated.'

        def resolve(id:, google_project_id_name: nil, client_email: nil, private_key: nil, log_id_name: nil, name: nil)
          config = authorized_find!(id)
          config_attributes = {
            google_project_id_name: google_project_id_name,
            client_email: client_email,
            private_key: private_key,
            log_id_name: log_id_name,
            name: name
          }.compact

          if config.update(config_attributes)
            audit_update(config)
            { google_cloud_logging_configuration: config, errors: [] }
          else
            { google_cloud_logging_configuration: nil, errors: Array(config.errors) }
          end
        end

        private

        def audit_update(config)
          AUDIT_EVENT_COLUMNS.each do |column|
            audit_changes(
              column,
              as: column.to_s,
              entity: config.group,
              model: config,
              event_type: UPDATE_EVENT_NAME
            )
          end
        end

        def find_object(config_gid)
          GitlabSchema.object_from_id(
            config_gid,
            expected_type: ::AuditEvents::GoogleCloudLoggingConfiguration).sync
        end
      end
    end
  end
end
