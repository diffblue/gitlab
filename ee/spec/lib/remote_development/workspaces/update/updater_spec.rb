# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::Update::Updater, feature_category: :remote_development do
  include ResultMatchers

  subject(:result) do
    described_class.update(workspace: workspace, params: params) # rubocop:disable Rails/SaveBang
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

  context 'when workspace update is successful' do
    it 'updates the workspace and returns ok result containing successful message with updated workspace' do
      expect { subject }.to change { workspace.reload.desired_state }.to(new_desired_state)

      expect(result)
        .to be_ok_result(RemoteDevelopment::Messages::WorkspaceUpdateSuccessful.new({ workspace: workspace }))
    end
  end

  context 'when workspace update fails' do
    let(:new_desired_state) { 'InvalidDesiredState' }

    it 'does not update the workspace and returns an error result containing a failed message with model errors' do
      expect { subject }.not_to change { workspace.reload }

      expect(result).to be_err_result do |message|
        expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceUpdateFailed)
        message.context => { errors: ActiveModel::Errors => errors }
        expect(errors.full_messages).to match([/desired state/i])
      end
    end
  end
end
