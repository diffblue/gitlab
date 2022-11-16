# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractionService do
  describe '#execute' do
    subject(:execute) { described_class.new(params).execute }

    let(:params) do
      {
        type: 'view_closed',
        event: {
          foo: 'bar'
        }
      }
    end

    it 'queues a interaction worker and returns success response' do
      expect(Integrations::SlackInteractivityWorker).to receive(:perform_async)
        .with(
          slack_interaction: 'view_closed',
          params: {
            event: {
              foo: 'bar'
            }
          }
        )

      expect(execute.payload).to eq({})

      is_expected.to be_success
    end

    context 'when event is unknown' do
      let(:params) { super().merge(type: 'foo') }

      it 'raises an error' do
        expect { execute }.to raise_error(described_class::UnknownInteractionError)
      end
    end
  end
end
