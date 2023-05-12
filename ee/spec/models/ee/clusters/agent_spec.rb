# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agent do
  let_it_be(:agent_1) { create(:ee_cluster_agent) }
  let_it_be(:agent_2) { create(:ee_cluster_agent) }
  let_it_be(:agent_3) { create(:ee_cluster_agent) }

  it { is_expected.to include_module(EE::Clusters::Agent) }
  it { is_expected.to have_many(:vulnerability_reads) }

  describe '.for_projects' do
    it 'return agents for selected projects' do
      expect(described_class.for_projects([agent_1.project, agent_3.project])).to contain_exactly(agent_1, agent_3)
    end
  end

  describe 'remote_development_agent_config scopes' do
    let_it_be(:agent_with_remote_development_agent_config) do
      create(:ee_cluster_agent, :with_remote_development_agent_config)
    end

    describe '.with_remote_development_agent_config' do
      it 'return agents with remote_development_agent_config' do
        expect(described_class.with_remote_development_agent_config)
          .to contain_exactly(agent_with_remote_development_agent_config)
        expect(described_class.with_remote_development_agent_config).not_to include(agent_1, agent_2, agent_3)
      end
    end

    describe '.without_remote_development_agent_config' do
      it 'return agents without remote_development_agent_config' do
        expect(described_class.without_remote_development_agent_config)
          .not_to include(agent_with_remote_development_agent_config)
        expect(described_class.without_remote_development_agent_config).to include(agent_1, agent_2, agent_3)
      end
    end
  end
end
