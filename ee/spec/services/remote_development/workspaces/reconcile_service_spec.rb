# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::ReconcileService, feature_category: :remote_development do
  describe '#execute' do
    let(:agent) { instance_double(Clusters::Agent, id: 1) }
    let(:params) { instance_double(Hash) }

    subject do
      described_class.new.execute(agent: agent, params: params)
    end

    context 'when params parse successfully' do
      let(:parsed_params) { { some_param: 'some value' } }

      before do
        allow_next_instance_of(RemoteDevelopment::Workspaces::Reconcile::ParamsParser) do |parser|
          allow(parser).to receive(:parse).with(params: params).and_return([parsed_params, nil])
        end

        allow_next_instance_of(RemoteDevelopment::Workspaces::Reconcile::ReconcileProcessor) do |processor|
          allow(processor).to receive(:process) do |**args|
            # rubocop:disable RSpec/ExpectInHook - not sure how to avoid this expectation without duplicating the block
            expect(args).to eq(agent: agent, **parsed_params)
            # rubocop:enable RSpec/ExpectInHook
          end.and_return(processor_result)
        end
      end

      context 'when reconciliation is successful' do
        let(:payload) { instance_double(Hash) }
        let(:processor_result) { [payload, nil] }

        it 'returns a success ServiceResponse' do
          expect(subject).to be_a(ServiceResponse)
          expect(subject.payload).to eq(payload)
          expect(subject.message).to be_nil
        end
      end

      context 'when reconciliation processing fails' do
        let(:message) { 'error message' }
        let(:reason) { :bad_request }
        let(:error) { RemoteDevelopment::Error.new(message: message, reason: reason) }
        let(:processor_result) { [nil, error] }

        it 'returns an error ServiceResponse' do
          expect(subject).to be_a(ServiceResponse)
          expect(subject.payload).to eq({}) # NOTE: A nil payload gets turned into an empty hash
          expect(subject.message).to eq(message)
          expect(subject.reason).to eq(reason)
        end
      end
    end

    context 'when params parsing fails' do
      let(:message) { 'error message' }
      let(:reason) { :unprocessable_entity }
      let(:error) { RemoteDevelopment::Error.new(message: message, reason: reason) }

      it 'returns an error ServiceResponse' do
        allow_next_instance_of(RemoteDevelopment::Workspaces::Reconcile::ParamsParser) do |parser|
          expect(parser).to receive(:parse).with(params: params).and_return([nil, error])
        end
        expect(subject).to be_a(ServiceResponse)
        expect(subject.payload).to eq({}) # NOTE: A nil payload gets turned into an empty hash
        expect(subject.message).to eq(message)
        expect(subject.reason).to eq(reason)
      end
    end

    context 'when there is an unexpected exception' do
      let(:reason) { :internal_server_error }
      let(:exception) { RuntimeError.new('unexpected error') }

      it 'returns an error ServiceResponse' do
        allow_next_instance_of(RemoteDevelopment::Workspaces::Reconcile::ParamsParser) do |parser|
          expect(parser).to receive(:parse).and_raise(exception)
        end

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(exception,
          error_type: 'reconcile',
          agent_id: agent.id
        )
        expect(subject).to be_a(ServiceResponse)
        expect(subject.payload).to eq({}) # NOTE: A nil payload gets turned into an empty hash
        expect(subject.message).to match(/Unexpected reconcile error/)
        expect(subject.reason).to eq(reason)
      end
    end
  end
end
