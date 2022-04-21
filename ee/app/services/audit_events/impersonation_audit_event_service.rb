# frozen_string_literal: true

module AuditEvents
  class ImpersonationAuditEventService < ::AuditEventService
    def initialize(author, ip_address, message, created_at)
      super(author, author, {
        action: :custom,
        custom_message: message,
        ip_address: ip_address
      }, :database_and_stream, created_at)
    end
  end
end
