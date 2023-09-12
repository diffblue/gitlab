# frozen_string_literal: true

module Types
  module AuditEvents
    module Instance
      class GoogleCloudLoggingConfigurationType < ::Types::BaseObject
        graphql_name 'InstanceGoogleCloudLoggingConfigurationType'
        description 'Stores instance level Google Cloud Logging configurations associated with IAM service accounts,' \
                    'used for generating access tokens.'
        authorize :admin_instance_external_audit_events

        implements GoogleCloudLoggingConfigurationInterface
      end
    end
  end
end
