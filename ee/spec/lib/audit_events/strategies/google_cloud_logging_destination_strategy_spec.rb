# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Strategies::GoogleCloudLoggingDestinationStrategy, feature_category: :audit_events do
  let(:group) { build(:group) }
  let(:event) { build(:audit_event, :group_event, target_group: group) }

  let_it_be(:event_type) { 'audit_operation' }
  let_it_be(:request_body) { { key: "value" }.to_json }

  describe '#streamable?' do
    subject { described_class.new(event_type, event).streamable? }

    context 'when feature is not licensed' do
      it { is_expected.to be_falsey }
    end

    context 'when feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      context 'when event group is nil' do
        let_it_be(:event) { build(:audit_event) }

        it { is_expected.to be_falsey }
      end

      context 'when group google cloud logging configurations does not exist' do
        it { is_expected.to be_falsey }
      end

      context 'when group google cloud logging configurations exist' do
        before do
          create(:google_cloud_logging_configuration, group: group)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#destinations' do
    subject { described_class.new(event_type, event).send(:destinations) }

    context 'when event group is nil' do
      let_it_be(:event) { build(:audit_event) }

      it 'returns empty array' do
        expect(subject).to eq([])
      end
    end

    context 'when group google cloud logging configurations exist' do
      it 'returns all the destinations' do
        destination1 = create(:google_cloud_logging_configuration, group: group)
        destination2 = create(:google_cloud_logging_configuration, group: group)

        expect(subject).to match_array([destination1, destination2])
      end
    end
  end

  describe '#track_and_stream' do
    let(:instance) { described_class.new(event_type, event) }
    let!(:destination) { create(:google_cloud_logging_configuration, group: group) }

    subject(:track_and_stream) { instance.send(:track_and_stream, destination) }

    context 'when a google cloud logging configuration exists' do
      let(:expected_log_entry) do
        [{ entries: {
          'logName' => destination.full_log_path,
          'resource' => {
            'type' => 'global'
          },
          'severity' => 'INFO',
          'jsonPayload' => ::Gitlab::Json.parse(request_body)
        } }.to_json]
      end

      before do
        allow_next_instance_of(GoogleCloud::LoggingService::Logger) do |instance|
          allow(instance).to receive(:log).and_return(nil)
        end
        allow(instance).to receive(:request_body).and_return(request_body)
      end

      it 'tracks audit event count and calls logger' do
        expect(instance).to receive(:track_audit_event_count)

        allow_next_instance_of(GoogleCloud::LoggingService::Logger) do |logger|
          expect(logger).to receive(:log).with(destination.client_email, destination.private_key, expected_log_entry)
        end

        track_and_stream
      end
    end
  end
end
