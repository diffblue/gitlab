# frozen_string_literal: true

module AuditEvents
  class InstanceExternalAuditEventDestinationPolicy < BasePolicy
    delegate { :global }
  end
end
