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
    it { is_expected.to validate_length_of(:destination_url).is_at_most(255) }
    it { is_expected.to validate_presence_of(:destination_url) }
    it { is_expected.to have_db_column(:verification_token).of_type(:text) }
    it { is_expected.to have_many(:headers).class_name('AuditEvents::Streaming::Header') }
    it { is_expected.to validate_length_of(:verification_token).is_at_least(16).is_at_most(24) }

    context 'when creating with undefined verification token' do
      let_it_be(:destination) { create(:external_audit_event_destination, verification_token: nil) }

      it 'destination is valid' do
        expect(destination).to be_valid
      end

      it 'verification token is present' do
        expect(destination.verification_token).to be_present
      end
    end

    context 'when updating' do
      before do
        destination.save!
      end

      it 'verification token cannot be nil' do
        destination.verification_token = nil

        expect(destination).not_to be_valid
      end
    end

    it 'can have 20 headers' do
      create_list(:audit_events_streaming_header, 20, external_audit_event_destination: subject)

      expect(subject).to be_valid
    end

    it 'can have no more than 20 headers' do
      create_list(:audit_events_streaming_header, 21, external_audit_event_destination: subject)

      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to contain_exactly('Headers are limited to 20 per destination')
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
end
