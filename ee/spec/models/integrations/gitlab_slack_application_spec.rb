# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::GitlabSlackApplication, feature_category: :integrations do
  include AfterNextHelpers

  it_behaves_like Integrations::BaseSlackNotification, factory: :gitlab_slack_application_integration do
    before do
      stub_request(:post, "#{::Slack::API::BASE_URL}/chat.postMessage").to_return(body: '{"ok":true}')
    end
  end

  describe 'validations' do
    it { is_expected.not_to validate_presence_of(:webhook) }
  end

  describe 'default values' do
    it { expect(subject.category).to eq(:chat) }

    it { is_expected.not_to be_alert_events }
    it { is_expected.not_to be_commit_events }
    it { is_expected.not_to be_confidential_issues_events }
    it { is_expected.not_to be_confidential_note_events }
    it { is_expected.not_to be_deployment_events }
    it { is_expected.not_to be_issues_events }
    it { is_expected.not_to be_job_events }
    it { is_expected.not_to be_merge_requests_events }
    it { is_expected.not_to be_note_events }
    it { is_expected.not_to be_pipeline_events }
    it { is_expected.not_to be_push_events }
    it { is_expected.not_to be_tag_push_events }
    it { is_expected.not_to be_vulnerability_events }
    it { is_expected.not_to be_wiki_page_events }
  end

  describe '#chat_responder' do
    it 'returns the chat responder to use' do
      expect(subject.chat_responder).to eq(Gitlab::Chat::Responder::Slack)
    end
  end

  describe '#execute' do
    let_it_be(:user) { build_stubbed(:user) }
    let_it_be(:slack_integration) { create(:slack_integration) }

    let(:data) { Gitlab::DataBuilder::Push.build_sample(integration.project, user) }
    let(:slack_api_method_uri) { "#{::Slack::API::BASE_URL}/chat.postMessage" }

    let(:mock_message) do
      instance_double(Integrations::ChatMessage::PushMessage, attachments: ['foo'], pretext: 'bar')
    end

    subject(:integration) { create(:gitlab_slack_application_integration, slack_integration: slack_integration) }

    before do
      allow(integration).to receive(:get_message).and_return(mock_message)
      allow(integration).to receive(:log_usage)
    end

    def stub_slack_request(channel: '#push_channel', success: true)
      post_body = {
        body: {
          attachments: mock_message.attachments,
          text: mock_message.pretext,
          unfurl_links: false,
          unfurl_media: false,
          channel: channel
        }
      }

      response = { ok: success }.to_json

      stub_request(:post, slack_api_method_uri).with(post_body)
        .to_return(body: response, headers: { 'Content-Type' => 'application/json; charset=utf-8' })
    end

    it 'notifies Slack' do
      stub_slack_request

      expect(integration.execute(data)).to be true
    end

    context 'when the flag is disabled' do
      before do
        stub_feature_flags(integration_slack_app_notifications: false)
      end

      it 'does not notify Slack' do
        expect(integration.execute(data)).to be false
      end
    end

    context 'when the integration is not configured for event' do
      before do
        integration.push_channel = nil
      end

      it 'does not notify Slack' do
        expect(integration.execute(data)).to be false
      end
    end

    context 'when Slack API responds with an error' do
      it 'logs the error and API response' do
        stub_slack_request(success: false)

        expect(Gitlab::IntegrationsLogger).to receive(:error).with(
          {
            integration_class: described_class.name,
            integration_id: integration.id,
            project_id: integration.project_id,
            project_path: kind_of(String),
            message: 'Slack API error when notifying',
            api_response: { 'ok' => false }
          }
        )
        expect(integration.execute(data)).to be false
      end
    end

    context 'when there is an HTTP error' do
      it 'logs the error' do
        expect_next(Slack::API).to receive(:post).and_raise(Net::ReadTimeout)
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(
          kind_of(Net::ReadTimeout),
          {
            slack_integration_id: slack_integration.id,
            integration_id: integration.id
          }
        )
        expect(integration.execute(data)).to be false
      end
    end

    context 'when configured to post to multiple Slack channels' do
      before do
        push_channels = '#first_channel, #second_channel'
        integration.push_channel = push_channels
      end

      it 'posts to both Slack channels and returns true' do
        stub_slack_request(channel: '#first_channel')
        stub_slack_request(channel: '#second_channel')

        expect(integration.execute(data)).to be true
      end

      context 'when one of the posts responds with an error' do
        it 'posts to both channels and returns true' do
          stub_slack_request(channel: '#first_channel', success: false)
          stub_slack_request(channel: '#second_channel')

          expect(Gitlab::IntegrationsLogger).to receive(:error).once
          expect(integration.execute(data)).to be true
        end
      end

      context 'when both of the posts respond with an error' do
        it 'posts to both channels and returns false' do
          stub_slack_request(channel: '#first_channel', success: false)
          stub_slack_request(channel: '#second_channel', success: false)

          expect(Gitlab::IntegrationsLogger).to receive(:error).twice
          expect(integration.execute(data)).to be false
        end
      end

      context 'when one of the posts raises an HTTP exception' do
        it 'posts to one channel and returns true' do
          stub_slack_request(channel: '#second_channel')

          expect_next_instance_of(Slack::API) do |api_client|
            expect(api_client).to receive(:post)
              .with('chat.postMessage', hash_including(channel: '#first_channel')).and_raise(Net::ReadTimeout)
            expect(api_client).to receive(:post)
              .with('chat.postMessage', hash_including(channel: '#second_channel')).and_call_original
          end
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).once
          expect(integration.execute(data)).to be true
        end
      end

      context 'when both of the posts raise an HTTP exception' do
        it 'posts to one channel and returns true' do
          stub_slack_request(channel: '#second_channel')

          expect_next(Slack::API).to receive(:post).twice.and_raise(Net::ReadTimeout)
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).twice
          expect(integration.execute(data)).to be false
        end
      end
    end
  end

  describe '#sections' do
    it 'includes the expected sections' do
      section_types = subject.sections.pluck(:type)

      expect(section_types).to eq(
        [
          described_class::SECTION_TYPE_TRIGGER,
          described_class::SECTION_TYPE_CONFIGURATION
        ]
      )
    end
  end

  context 'when the integration is disabled' do
    before do
      subject.active = false
    end

    it 'is not editable, and presents no editable fields' do
      expect(subject).not_to be_editable
      expect(subject.fields).to be_empty
      expect(subject.configurable_events).to be_empty
    end
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(integration_slack_app_notifications: false)
    end

    it 'is not editable, and presents no editable fields' do
      expect(subject).not_to be_editable
      expect(subject.fields).to be_empty
      expect(subject.configurable_events).to be_empty
    end
  end

  describe '#description' do
    it 'mentions notifications only when the flag is disabled' do
      expect(subject.description).to include('notifications')

      stub_feature_flags(integration_slack_app_notifications: false)

      expect(subject.description).not_to include('notifications')
    end
  end

  describe '#upgrade_needed?' do
    context 'with all_features_supported' do
      subject(:integration) { create(:gitlab_slack_application_integration, :all_features_supported) }

      it 'is false' do
        expect(integration).not_to be_upgrade_needed
      end
    end

    context 'without all_features_supported' do
      subject(:integration) { create(:gitlab_slack_application_integration) }

      it 'is true' do
        expect(integration).to be_upgrade_needed
      end
    end

    context 'without slack_integration' do
      subject(:integration) { create(:gitlab_slack_application_integration, slack_integration: nil) }

      it 'is false' do
        expect(integration).not_to be_upgrade_needed
      end
    end
  end
end
