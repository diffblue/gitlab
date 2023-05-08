# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::RemoteDevelopmentAgentConfig, feature_category: :remote_development do
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }

  subject { agent.remote_development_agent_config }

  describe 'associations' do
    it { is_expected.to belong_to(:agent) }
    it { is_expected.to have_many(:workspaces) }

    context 'with associated workspaces' do
      let(:workspace_1) { create(:workspace, agent: agent) }
      let(:workspace_2) { create(:workspace, agent: agent) }

      it 'has correct associations from factory' do
        expect(subject.reload.workspaces).to contain_exactly(workspace_1, workspace_2)
        expect(workspace_1.remote_development_agent_config).to eq(subject)
      end
    end
  end

  describe '#after_update' do
    it 'prevents dns_zone from being updated' do
      subject.update(dns_zone: 'new-zone') # rubocop:disable Rails/SaveBang
      expect(subject.errors.full_messages)
        .to match_array(['Dns zone is currently immutable, and cannot be updated. Create a new agent instead.'])
    end
  end
end
