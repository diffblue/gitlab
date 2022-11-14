# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::EventTypeFilter do
  subject(:event_type_filter) { build(:audit_events_streaming_event_type_filter) }

  describe 'Associations' do
    it 'belongs to a external audit event destination' do
      expect(subject.external_audit_event_destination).not_to be_nil
    end
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:audit_event_type) }
    it { is_expected.to validate_length_of(:audit_event_type).is_at_most(255) }
    it { is_expected.to belong_to(:external_audit_event_destination) }
    it { is_expected.to validate_uniqueness_of(:audit_event_type).scoped_to(:external_audit_event_destination_id) }
  end

  describe '.audit_event_type_in' do
    let_it_be(:filter1) { create(:audit_events_streaming_event_type_filter) }
    let_it_be(:filter2) { create(:audit_events_streaming_event_type_filter) }

    subject { described_class.audit_event_type_in(filter1.audit_event_type) }

    it 'returns the correct audit events' do
      expect(subject).to contain_exactly(filter1)
    end
  end

  describe '#to_s' do
    subject { event_type_filter.to_s }

    it { is_expected.to eq(event_type_filter.audit_event_type) }
  end
end
