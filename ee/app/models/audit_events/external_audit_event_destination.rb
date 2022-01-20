# frozen_string_literal: true

module AuditEvents
  class ExternalAuditEventDestination < ApplicationRecord
    include Limitable

    self.limit_name = 'external_audit_event_destinations'
    self.limit_scope = :group
    self.table_name = 'audit_events_external_audit_event_destinations'

    belongs_to :group, class_name: '::Group', foreign_key: 'namespace_id'

    validates :destination_url, public_url: true, presence: true
    validates :destination_url, uniqueness: { scope: :namespace_id }, length: { maximum: 255 }
    has_secure_token :verification_token, length: 24
  end
end
