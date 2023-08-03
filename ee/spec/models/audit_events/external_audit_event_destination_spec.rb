# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::ExternalAuditEventDestination, feature_category: :audit_events do
  subject(:destination) { build(:external_audit_event_destination) }

  let_it_be(:group) { create(:group) }

  describe 'Associations' do
    it 'belongs to a group' do
      expect(subject.group).not_to be_nil
    end
  end

  describe 'Validations' do
    it { is_expected.to have_db_column(:verification_token).of_type(:text) }
    it { is_expected.to have_many(:headers).class_name('AuditEvents::Streaming::Header') }

    it 'can have 20 headers' do
      create_list(:audit_events_streaming_header, 20, external_audit_event_destination: subject)

      expect(subject).to be_valid
    end

    it 'can have no more than 20 headers' do
      create_list(:audit_events_streaming_header, 21, external_audit_event_destination: subject)

      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to contain_exactly('Headers are limited to 20 per destination')
    end

    context 'for destination_url' do
      let_it_be(:group_2) { create(:group) }

      it 'does not create destination with same url for a group' do
        create(:external_audit_event_destination, destination_url: 'http://www.test.com', group: group)
        destination = build(:external_audit_event_destination, destination_url: 'http://www.test.com', group: group)

        expect(destination).not_to be_valid
        expect(destination.errors.full_messages).to include('Destination url has already been taken')
      end

      it 'creates destination with same url for different groups' do
        create(:external_audit_event_destination, destination_url: 'http://www.test.com', group: group)
        destination = build(:external_audit_event_destination, destination_url: 'http://www.test.com', group: group_2)

        expect(destination).to be_valid
      end
    end

    it 'validates uniqueness of name scoped to namespace' do
      create(:external_audit_event_destination, name: 'Test Destination', group: group)
      destination = build(:external_audit_event_destination, name: 'Test Destination', group: group)

      expect(destination).not_to be_valid
      expect(destination.errors.full_messages).to include('Name has already been taken')
    end
  end

  describe '#headers_hash' do
    subject { destination.headers_hash }

    context "when destination has 2 headers" do
      before do
        create(:audit_events_streaming_header, external_audit_event_destination: destination, key: 'X-GitLab-Hello')
        create(:audit_events_streaming_header, external_audit_event_destination: destination, key: 'X-GitLab-World')
      end

      it do
        is_expected.to eq({ 'X-GitLab-Hello' => 'bar',
                            'X-GitLab-World' => 'bar',
                            'X-Gitlab-Event-Streaming-Token' => destination.verification_token })
      end
    end

    it 'must have a unique destination_url', :aggregate_failures do
      create(:external_audit_event_destination, destination_url: 'https://example.com/1', group: group)
      dup = build(:external_audit_event_destination, destination_url: 'https://example.com/1', group: group)

      expect(dup).to be_invalid
      expect(dup.errors.full_messages).to include('Destination url has already been taken')
    end

    it 'must not have any parents', :aggregate_failures do
      destination = build(:external_audit_event_destination, group: create(:group, :nested))

      expect(destination).to be_invalid
      expect(destination.errors.full_messages).to include('Group must not be a subgroup')
    end
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:external_audit_event_destination, group: create(:group)) }
  end

  it_behaves_like 'includes ExternallyDestinationable concern' do
    subject(:destination) { build(:external_audit_event_destination, group: create(:group)) }

    subject(:destination_without_verification_token) do
      create(:external_audit_event_destination, verification_token: nil)
    end

    let_it_be(:audit_operation) { 'audit_operation' }
    let_it_be(:destination_with_filters_of_given_type) { create(:external_audit_event_destination) }
    let_it_be(:filter1) do
      create(:audit_events_streaming_event_type_filter,
        external_audit_event_destination: destination_with_filters_of_given_type,
        audit_event_type: 'audit_operation')
    end

    let_it_be(:filter2) do
      create(:audit_events_streaming_event_type_filter,
        external_audit_event_destination: destination_with_filters_of_given_type,
        audit_event_type: 'audit_operation1')
    end

    let_it_be(:destination_with_filters) { create(:external_audit_event_destination) }
    let!(:filter3) do
      create(:audit_events_streaming_event_type_filter,
        external_audit_event_destination: destination_with_filters)
    end
  end

  it_behaves_like 'includes ExternallyCommonDestinationable concern' do
    let(:model_factory_name) { :external_audit_event_destination }
  end

  describe '#audit_details' do
    it "equals to the destination url" do
      expect(destination.audit_details).to eq(destination.destination_url)
    end
  end
end
