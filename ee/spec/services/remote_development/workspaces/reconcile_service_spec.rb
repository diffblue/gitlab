# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::ReconcileService, feature_category: :remote_development do
  let(:agent) { instance_double(Clusters::Agent, id: 1) }
  let(:params) { instance_double(Hash) }
  let(:workspace_rails_infos) { [] }

  describe '#execute' do
    subject(:service_response) do
      described_class.new.execute(agent: agent, params: params)
    end

    before do
      allow(RemoteDevelopment::Workspaces::Reconcile::Main)
        .to receive(:main).with(
          agent: agent,
          original_params: params,
          logger: instance_of(RemoteDevelopment::Logger)
        ).and_return(response_hash)
    end

    context 'when success' do
      let(:response_hash) { { status: :success, payload: { workspace_rails_infos: workspace_rails_infos } } }

      it 'returns a success ServiceResponse' do
        expect(service_response).to be_success
        expect(service_response.payload.fetch(:workspace_rails_infos)).to eq(workspace_rails_infos)
      end
    end

    context 'when error' do
      let(:response_hash) { { status: :error, message: 'error', reason: :bad_request } }

      it 'returns an error success ServiceResponse' do
        expect(service_response).to be_error
        service_response => { message:, reason: }
        expect(message).to eq('error')
        expect(reason).to eq(:bad_request)
      end
    end
  end
end
