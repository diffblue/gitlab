# frozen_string_literal: true

module Resolvers
  module AuditEvents
    class InstanceExternalAuditEventDestinationsResolver < BaseResolver
      include LooksAhead

      type [::Types::AuditEvents::InstanceExternalAuditEventDestinationType], null: true

      def resolve_with_lookahead
        apply_lookahead(::AuditEvents::InstanceExternalAuditEventDestination.all)
      end

      def preloads
        {
          headers: [:headers]
        }
      end
    end
  end
end
