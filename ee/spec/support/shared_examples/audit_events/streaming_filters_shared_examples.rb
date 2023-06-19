# frozen_string_literal: true

# This example expects 2 variables named filter1 and filter2.
# They are audit event type filters for streaming audit events to external destinations.
# They are being used here for testing methods of streaming filter models.
RSpec.shared_examples 'audit event streaming filter' do
  describe 'Validations' do
    it { is_expected.to validate_presence_of(:audit_event_type) }
    it { is_expected.to validate_length_of(:audit_event_type).is_at_most(255) }
  end

  describe '.audit_event_type_in' do
    subject { described_class.audit_event_type_in(filter1.audit_event_type) }

    it 'returns the correct audit events' do
      expect(subject).to contain_exactly(filter1)
    end
  end

  describe '#to_s' do
    subject { event_type_filter.to_s }

    it { is_expected.to eq(event_type_filter.audit_event_type) }
  end

  describe '.pluck_audit_event_type' do
    subject(:pluck_audit_event_type) { described_class.pluck_audit_event_type }

    it 'returns the audit event type of the event type filter' do
      expect(pluck_audit_event_type).to contain_exactly(filter1.audit_event_type, filter2.audit_event_type)
    end
  end
end
