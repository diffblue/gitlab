# frozen_string_literal: true

module AuditEvents
  module Strategies
    class GroupExternalDestinationStrategy < ExternalDestinationStrategy
      def streamable?
        group = audit_event.root_group_entity
        return false if group.nil?
        return false unless group.licensed_feature_available?(:external_audit_events)

        group.external_audit_event_destinations.exists?
      end

      private

      def destinations
        group = audit_event.root_group_entity
        group.present? ? group.external_audit_event_destinations.to_a : []
      end
    end
  end
end
