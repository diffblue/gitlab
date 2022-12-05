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
    let(:ctx) { { current_user: current_user } }
    let(:params) { {} }
    let_it_be(:maintainer) { create(:user, developer_projects: [project]) }
    let_it_be(:reporter) { create(:user) }

    let_it_be(:agent_with_vulnerabilities) { create(:cluster_agent, project: project, has_vulnerabilities: true) }
    let_it_be(:agent_without_vulnerabilities) { create(:cluster_agent, project: project, has_vulnerabilities: false) }

    before do
      project.add_reporter(reporter)
    end

    subject { resolve_agents(params) }

    context 'the current user has access to clusters' do
      let(:current_user) { maintainer }

      it 'finds all agents' do
        expect(subject).to contain_exactly(agent_with_vulnerabilities, agent_without_vulnerabilities)
      end

      context 'when has_vulnerabilities argument is provided' do
        let(:params) { { has_vulnerabilities: has_vulnerabilities } }

        context 'when has_vulnerabilities is set to true' do
          let(:has_vulnerabilities) { true }

          it 'returns only agents with vulnerabilities' do
            expect(subject).to contain_exactly(agent_with_vulnerabilities)
          end
        end

        context 'when has_vulnerabilities is set to false' do
          let(:has_vulnerabilities) { false }

          it 'returns only agents without vulnerabilities' do
            expect(subject).to contain_exactly(agent_without_vulnerabilities)
          end
        end
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
