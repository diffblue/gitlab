# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Clusters::AgentsResolver do
  include GraphqlHelpers

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Clusters::AgentType.connection_type)
  end

  specify do
    expect(described_class.field_options).to include(extras: include(:lookahead))
  end

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:maintainer) { create(:user, developer_projects: [project]) }
    let_it_be(:reporter) { create(:user) }

    let_it_be(:agent_1) { create(:cluster_agent, project: project) }
    let_it_be(:agent_2) { create(:cluster_agent, project: project) }

    before do
      project.add_reporter(reporter)
    end

    let(:ctx) { { current_user: current_user } }
    let(:params) { {} }

    subject { resolve_agents(params) }

    context 'the current user has access to clusters' do
      let(:current_user) { maintainer }

      it 'finds all agents' do
        expect(subject).to contain_exactly(agent_1, agent_2)
      end
    end

    context 'the current user does not have access to clusters' do
      let(:current_user) { reporter }

      it 'returns an empty result' do
        expect(subject).to be_empty
      end
    end
  end

  def resolve_agents(args = {})
    resolve(described_class, obj: project, ctx: ctx, lookahead: positive_lookahead, args: args)
  end
end
