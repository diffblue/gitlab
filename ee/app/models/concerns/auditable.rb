# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern
  include AfterCommitQueue

  def push_audit_event(event)
    return unless ::Gitlab::Audit::EventQueue.active?

    run_after_commit do
      ::Gitlab::Audit::EventQueue.push(event)
    end
  end

  def audit_details
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end
end
