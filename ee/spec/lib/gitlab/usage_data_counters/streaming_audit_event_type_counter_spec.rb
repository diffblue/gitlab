# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::StreamingAuditEventTypeCounter do
  described_class::KNOWN_EVENTS.each do |event|
    it_behaves_like 'a redis usage counter', 'StreamingAuditEventType', event
    it_behaves_like 'a redis usage counter with totals', :audit_events, "#{event}": 5
  end
end
