# frozen_string_literal: true

module Resolvers
  module AuditEvents
    class InstanceExternalAuditEventDestinationsResolver < BaseResolver
      type [::Types::AuditEvents::InstanceExternalAuditEventDestinationType], null: true

      def resolve
        ::AuditEvents::InstanceExternalAuditEventDestination.all
      end
    end
  end
end
