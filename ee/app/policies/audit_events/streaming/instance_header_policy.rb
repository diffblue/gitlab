# frozen_string_literal: true

module AuditEvents
  module Streaming
    class InstanceHeaderPolicy < ::BasePolicy
      delegate { @subject.instance_external_audit_event_destination }
    end
  end
end
