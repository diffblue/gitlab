# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::Update::Main, "Integration", feature_category: :remote_development do
  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { user }
  let_it_be(:workspace, refind: true) do
    create(:workspace, user: user, desired_state: RemoteDevelopment::Workspaces::States::RUNNING)
  end

  let(:new_desired_state) { RemoteDevelopment::Workspaces::States::STOPPED }
  let(:params) { { desired_state: new_desired_state } }
  let(:value) { { workspace: workspace, current_user: current_user, params: params } }

  subject(:response) do
    described_class.main(value)
  end

  context 'when workspace update is successful' do
    it 'updates the workspace and returns success' do
      expect { subject }.to change { workspace.reload.desired_state }.to(new_desired_state)

      expect(response).to eq({
        status: :success,
        payload: { workspace: workspace }
      })
    end
  end

  context 'when workspace update fails' do
    let(:new_desired_state) { 'InvalidDesiredState' }

    it 'does not update the workspace and returns error' do
      expect { subject }.not_to change { workspace.reload }

      expect(response).to eq({
        status: :error,
        message: "Workspace update failed: Desired state is not included in the list",
        reason: :bad_request
      })
    end
  end
end
