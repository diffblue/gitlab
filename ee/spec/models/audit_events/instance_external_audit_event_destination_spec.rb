# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::InstanceExternalAuditEventDestination, feature_category: :audit_events do
  subject(:destination) { build(:instance_external_audit_event_destination) }

  it_behaves_like 'includes ExternallyDestinationable concern' do
    subject(:destination_without_verification_token) do
      create(:instance_external_audit_event_destination, verification_token: nil)
    end
  end

  it_behaves_like 'includes Limitable concern'

  describe 'Validations' do
    it { is_expected.to have_many(:headers).class_name('AuditEvents::Streaming::InstanceHeader') }

    it 'can have 20 headers' do
      create_list(:instance_audit_events_streaming_header, 20, instance_external_audit_event_destination: subject)

      expect(subject).to be_valid
    end

    it 'can have no more than 20 headers' do
      create_list(:instance_audit_events_streaming_header, 21, instance_external_audit_event_destination: subject)

      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to contain_exactly('Headers are limited to 20 per destination')
    end

    it 'validates uniqueness of destination_url' do
      create(:instance_external_audit_event_destination, destination_url: 'https://www.test.com')
      destination = build(:instance_external_audit_event_destination, destination_url: 'https://www.test.com')

      expect(destination).not_to be_valid
      expect(destination.errors.full_messages).to include('Destination url has already been taken')
    end

    it 'validates uniqueness of name' do
      create(:instance_external_audit_event_destination, name: 'Test Destination')
      destination = build(:instance_external_audit_event_destination, name: 'Test Destination')

      expect(destination).not_to be_valid
      expect(destination.errors.full_messages).to include('Name has already been taken')
    end
  end

  describe '#headers_hash' do
    subject { destination.headers_hash }

    context "when destination has 2 headers" do
      before do
        create(:instance_audit_events_streaming_header, instance_external_audit_event_destination: destination,
          key: 'X-GitLab-Hello')
        create(:instance_audit_events_streaming_header, instance_external_audit_event_destination: destination,
          key: 'X-GitLab-World')
      end

      it do
        is_expected.to eq({ 'X-GitLab-Hello' => 'bar',
                            'X-GitLab-World' => 'bar',
                            'X-Gitlab-Event-Streaming-Token' => destination.verification_token })
      end
    end

    it 'must have a unique destination_url', :aggregate_failures do
      create(:instance_external_audit_event_destination, destination_url: 'https://example.com/1')
      dup = build(:instance_external_audit_event_destination, destination_url: 'https://example.com/1')

      expect(dup).to be_invalid
      expect(dup.errors.full_messages).to include('Destination url has already been taken')
    end
  end
end
