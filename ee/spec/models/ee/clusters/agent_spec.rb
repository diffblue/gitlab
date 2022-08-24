# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agent do
  it { is_expected.to include_module(EE::Clusters::Agent) }
  it { is_expected.to have_many(:vulnerability_reads) }

  describe '.for_projects' do
    let_it_be(:agent_1) { create(:cluster_agent) }
    let_it_be(:agent_2) { create(:cluster_agent) }
    let_it_be(:agent_3) { create(:cluster_agent) }

    it 'return agents for selected projects' do
      expect(described_class.for_projects([agent_1.project, agent_3.project])).to contain_exactly(agent_1, agent_3)
    end
  end
end
