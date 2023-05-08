# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::Update::UpdateProcessor, feature_category: :remote_development do
  subject(:results) do
    described_class.new.process(workspace: workspace, params: params)
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { user }
  let_it_be(:workspace, refind: true) do
    create(:workspace, user: user, desired_state: RemoteDevelopment::Workspaces::States::RUNNING)
  end

  let(:new_desired_state) { RemoteDevelopment::Workspaces::States::STOPPED }
  let(:params) do
    {
      desired_state: new_desired_state
    }
  end

  describe '#process' do
    context 'when workspace update is successful' do
      it 'updates the workspace and returns success' do
        expect { subject }.to change { workspace.reload.desired_state }.to(new_desired_state)

        payload, error = subject
        expect(payload).to eq({ workspace: workspace })
        expect(error).to be_nil
      end
    end

    context 'when workspace update fails' do
      let(:new_desired_state) { 'InvalidDesiredState' }

      it 'does not update the workspace and returns error' do
        expect { subject }.not_to change { workspace.reload }

        payload, error = subject
        expect(payload).to be_nil
        expect(error.message).to match(/Error/)
        expect(error.reason).to eq(:bad_request)
      end
    end
  end
end
