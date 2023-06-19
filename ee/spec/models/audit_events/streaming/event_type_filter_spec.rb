# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::EventTypeFilter, feature_category: :audit_events do
  subject(:event_type_filter) { build(:audit_events_streaming_event_type_filter) }

  describe 'Associations' do
    it 'belongs to a external audit event destination' do
      expect(subject.external_audit_event_destination).not_to be_nil
    end
  end

  describe 'Validations' do
    it { is_expected.to belong_to(:external_audit_event_destination) }
    it { is_expected.to validate_uniqueness_of(:audit_event_type).scoped_to(:external_audit_event_destination_id) }
  end

  it_behaves_like 'audit event streaming filter' do
    let_it_be(:filter1) { create(:audit_events_streaming_event_type_filter) }
    let_it_be(:filter2) { create(:audit_events_streaming_event_type_filter) }
  end
end
