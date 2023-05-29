# frozen_string_literal: true

module AuditEvents
  class ExternalAuditEventDestination < ApplicationRecord
    include ExternallyDestinationable
    include Limitable

    MAXIMUM_HEADER_COUNT = 20

    self.limit_name = 'external_audit_event_destinations'
    self.limit_scope = :group
    self.table_name = 'audit_events_external_audit_event_destinations'

    belongs_to :group, class_name: '::Group', foreign_key: 'namespace_id', inverse_of: :audit_events
    has_many :headers, class_name: 'AuditEvents::Streaming::Header'
    has_many :event_type_filters, class_name: 'AuditEvents::Streaming::EventTypeFilter'

    validate :has_fewer_than_20_headers?
    validate :root_level_group?

    def headers_hash
      { STREAMING_TOKEN_HEADER_KEY => verification_token }.merge(headers.map(&:to_hash).inject(:merge).to_h)
    end

    # TODO: Remove audit_operation.present? guard clause once we implement names for all the audit event types.
    # Epic: https://gitlab.com/groups/gitlab-org/-/epics/8497
    def allowed_to_stream?(audit_operation)
      return true unless audit_operation.present?
      return true unless event_type_filters.exists?

      event_type_filters.audit_event_type_in(audit_operation).exists?
    end

    private

    def has_fewer_than_20_headers?
      return unless headers.count > MAXIMUM_HEADER_COUNT

      errors.add(:headers, "are limited to #{MAXIMUM_HEADER_COUNT} per destination")
    end

    def root_level_group?
      errors.add(:group, 'must not be a subgroup') if group.subgroup?
    end
  end
end
