# frozen_string_literal: true

module AuditEvents
  class ExternalAuditEventDestinationPolicy < ::BasePolicy
    delegate { @subject.group }
  end
end
