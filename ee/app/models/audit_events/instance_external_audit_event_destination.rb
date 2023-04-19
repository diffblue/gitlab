# frozen_string_literal: true

module AuditEvents
  class InstanceExternalAuditEventDestination < ApplicationRecord
    include ExternallyDestinationable
    include Limitable

    self.limit_name = 'external_audit_event_destinations'
    self.limit_scope = Limitable::GLOBAL_SCOPE
    self.table_name = 'audit_events_instance_external_audit_event_destinations'

    attr_encrypted :verification_token,
      mode: :per_attribute_iv,
      algorithm: 'aes-256-gcm',
      key: Settings.attr_encrypted_db_key_base_32,
      encode: false,
      encode_iv: false
  end
end
