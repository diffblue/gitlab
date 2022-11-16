# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::GitlabSlackApplication do
  it_behaves_like Integrations::BaseSlackNotification, factory: :gitlab_slack_application_integration

  describe 'validations' do
    it { is_expected.not_to validate_presence_of(:webhook) }
  end

  describe 'default values' do
    it { expect(subject.category).to eq(:chat) }
  end

  describe '#chat_responder' do
    it 'returns the chat responder to use' do
      expect(subject.chat_responder).to eq(Gitlab::Chat::Responder::Slack)
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
end
