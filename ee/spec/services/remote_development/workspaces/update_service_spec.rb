# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::UpdateService, feature_category: :remote_development do
  let(:workspace) { build_stubbed(:workspace) }
  let(:user) { instance_double(User) }
  let(:params) { instance_double(Hash) }

  describe '#execute' do
    subject(:service_response) do
      described_class.new(current_user: user).execute(workspace: workspace, params: params)
    end

    before do
      allow(RemoteDevelopment::Workspaces::Update::Main)
        .to receive(:main).with(workspace: workspace, current_user: user, params: params).and_return(response_hash)
    end

    context 'when success' do
      let(:response_hash) { { status: :success, payload: { workspace: workspace } } }

      it 'returns a success ServiceResponse' do
        expect(service_response).to be_success
        expect(service_response.payload.fetch(:workspace)).to eq(workspace)
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
