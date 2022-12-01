# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractivityWorker, :clean_gitlab_redis_shared_state do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:slack_integration) { create(:slack_integration) }

  describe '.interaction?' do
    context 'when slack_interaction is known/unknown' do
      where(:slack_interaction, :result) do
        'view_closed'     | true
        'view_submission' | true
        'foo'             | false
      end

      with_them do
        it 'returns correct result' do
          expect(described_class.interaction?(slack_interaction)).to be(result)
        end
      end
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

    let(:args) do
      {
        slack_interaction: slack_interaction,
        params: params
      }
    end

    let(:params) do
      {
        user: {
          id: slack_integration.user_id
        },
        team: {
          id: slack_integration.team_id
        },
        view: {
          private_metadata: 'https://response.slack.com/id/123',
          state: {
            values: {}
          }
        }
      }
    end

    shared_examples 'logs extra metadata on done' do
      specify do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:slack_interaction, slack_interaction)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:slack_user_id, slack_integration.user_id)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:slack_workspace_id, slack_integration.team_id)

        worker.perform(args)
      end
    end

    context 'when view is closed' do
      let(:slack_interaction) { 'view_closed' }

      it 'executes the correct service' do
        view_closed_service = described_class::INTERACTIONS['view_closed']

        expect_next_instance_of(view_closed_service, params) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        worker.perform(args)
      end

      it_behaves_like 'logs extra metadata on done'
    end

    context 'when view is submitted' do
      let(:slack_interaction) { 'view_submission' }

      it 'executes the submission service' do
        view_submission_service = described_class::INTERACTIONS['view_submission']

        expect_next_instance_of(view_submission_service, params) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        worker.perform(args)
      end

      it_behaves_like 'logs extra metadata on done'
    end

    context 'when slack_interaction is not known' do
      let(:slack_interaction) { 'foo' }

      it 'does not execute a service class' do
        described_class::INTERACTIONS.each_value do |service_class|
          expect(service_class).not_to receive(:new)
        end

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
