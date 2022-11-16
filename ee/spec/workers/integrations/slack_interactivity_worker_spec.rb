# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractivityWorker, :clean_gitlab_redis_shared_state do
  describe '.interaction?' do
    subject { described_class.interaction?(slack_interaction) }

    context 'when slack_interaction is known' do
      let(:slack_interaction) { 'view_closed' }

      it { is_expected.to be_truthy }
    end

    context 'when slack_interaction is not known' do
      let(:slack_interaction) { 'foo' }

      it { is_expected.to be_falsey }
    end
  end

  describe '#perform' do
    before do
      stub_request(:post, 'https://response.slack.com/id/123')
        .to_return(
          status: 200,
          body: Gitlab::Json.dump({ ok: true }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    let(:worker) { described_class.new }
    let(:slack_interaction) { 'view_closed' }
    let(:service_class) { ::Integrations::SlackInteractions::IncidentManagement::IncidentModalClosedService }

    let(:args) do
      {
        slack_interaction: slack_interaction,
        params: params
      }
    end

    let(:params) do
      {
        user: {
          id: 'U0123ABCDEF'
        },
        team: {
          id: 'T0123A456BC'
        },
        view: {
          private_metadata: 'https://response.slack.com/id/123'
        }
      }
    end

    shared_examples 'logs extra metadata on done' do
      specify do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:slack_interaction, slack_interaction)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:slack_user_id, 'U0123ABCDEF')
        expect(worker).to receive(:log_extra_metadata_on_done).with(:slack_workspace_id, 'T0123A456BC')

        worker.perform(args)
      end
    end

    it 'executes the correct service' do
      expect_next_instance_of(service_class, params) do |service|
        expect(service).to receive(:execute).and_return(ServiceResponse.success)
      end

      worker.perform(args)
    end

    it_behaves_like 'logs extra metadata on done'

    context 'when slack_interaction is not known' do
      let(:slack_interaction) { 'foo' }

      it 'does not execute the service class' do
        expect(service_class).not_to receive(:new)

        worker.perform(args)
      end

      it 'logs an error' do
        expect(Sidekiq.logger).to receive(:error).with(
          { message: 'Unknown slack_interaction', slack_interaction: slack_interaction }
        )

        worker.perform(args)
      end

      it_behaves_like 'logs extra metadata on done'
    end
  end
end
