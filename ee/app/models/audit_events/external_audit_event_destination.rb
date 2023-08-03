# frozen_string_literal: true

module AuditEvents
  class ExternalAuditEventDestination < ApplicationRecord
    include ExternallyDestinationable
    include Limitable
    include ExternallyCommonDestinationable

    self.limit_name = 'external_audit_event_destinations'
    self.limit_scope = :group
    self.table_name = 'audit_events_external_audit_event_destinations'

    belongs_to :group, class_name: '::Group', foreign_key: 'namespace_id', inverse_of: :audit_events
    has_many :headers, class_name: 'AuditEvents::Streaming::Header'
    has_many :event_type_filters, class_name: 'AuditEvents::Streaming::EventTypeFilter'

    validate :root_level_group?
    validates :name, uniqueness: { scope: :namespace_id }
    validates :destination_url, uniqueness: { scope: :namespace_id }, length: { maximum: 255 }

    private

    def root_level_group?
      errors.add(:group, 'must not be a subgroup') if group.subgroup?
    end
  end
end
