# frozen_string_literal: true

module Mutations
  module AuditEvents
    module GoogleCloudLoggingConfigurations
      class Destroy < BaseMutation
        graphql_name 'GoogleCloudLoggingConfigurationDestroy'

        authorize :admin_external_audit_events

        argument :id, ::Types::GlobalIDType[::AuditEvents::GoogleCloudLoggingConfiguration],
          required: true,
          description: 'ID of the google cloud logging configuration to destroy.'

        def resolve(id:)
          config = authorized_find!(id)

          if config.destroy
            { errors: [] }
          else
            { errors: Array(config.errors) }
          end
        end

        private

        def find_object(config_gid)
          GitlabSchema.object_from_id(
            config_gid,
            expected_type: ::AuditEvents::GoogleCloudLoggingConfiguration).sync
        end
      end
    end
  end
end
