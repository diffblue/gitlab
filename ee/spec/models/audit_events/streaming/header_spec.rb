# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::Header, feature_category: :audit_events do
  subject(:header) { build(:audit_events_streaming_header, key: 'foo', value: 'bar') }

  describe 'Validations' do
    it { is_expected.to belong_to(:external_audit_event_destination) }
    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:external_audit_event_destination_id) }
  end

  include_examples 'audit event streaming header'
end
