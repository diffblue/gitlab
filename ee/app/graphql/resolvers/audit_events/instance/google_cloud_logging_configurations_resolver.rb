# frozen_string_literal: true

module Resolvers
  module AuditEvents
    module Instance
      class GoogleCloudLoggingConfigurationsResolver < BaseResolver
        type [::Types::AuditEvents::Instance::GoogleCloudLoggingConfigurationType], null: true

        def resolve
          # There is a limit of maximum 5 GCL configs per instance and also for graphql queries there is a limit of 100
          # records per page so using `all` is ok here.
          ::AuditEvents::Instance::GoogleCloudLoggingConfiguration.all
        end
      end
    end
  end
end
