# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::Header, feature_category: :audit_events do
  subject(:header) { build(:audit_events_streaming_header, key: 'foo', value: 'bar') }

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_length_of(:key).is_at_most(255) }
    it { is_expected.to validate_length_of(:value).is_at_most(255) }
    it { is_expected.to belong_to(:external_audit_event_destination) }
    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:external_audit_event_destination_id) }
  end

  describe '#to_hash' do
    subject { header.to_hash }

    it { is_expected.to eq({ 'foo' => 'bar' }) }
  end
end
