# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::WorkspacePolicy, feature_category: :remote_development do
  let(:current_user) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let_it_be(:project) { create(:project) }
  let(:workspace) { build(:workspace, project: project, agent: agent) }

  subject(:policy) { described_class.new(current_user, workspace) }

  before do
    project.add_developer(developer)
  end

  describe 'update_workspace' do
    context 'when the workspace belongs to another user and the user does not have develop access' do
      it { is_expected.to be_disallowed(:update_workspace) }
    end

    context 'when the workspace belongs to the user' do
      before do
        # An unexpected state
        # this is done after building the workspace to avoid the factory adding the user as a developer
        workspace.user = current_user
      end

      context 'and the user does not have developer access to the project' do
        it { is_expected.to be_disallowed(:update_workspace) }
      end
    end

    context 'when the user has developer access' do
      let(:current_user) { developer }

      context 'and the workspace belongs to another user' do
        it { is_expected.to be_disallowed(:update_workspace) }
      end

      context 'and the workspace belongs to the user' do
        let(:workspace) { build(:workspace, project: project, agent: agent, user: current_user) }

        it { is_expected.to be_allowed(:update_workspace) }
      end
    end
  end
end
