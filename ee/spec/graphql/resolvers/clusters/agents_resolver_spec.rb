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

    before do
      project.add_reporter(reporter)
    end

    subject { resolve_agents(params) }

    context 'the current user has access to clusters' do
      let(:current_user) { maintainer }

      context 'when no filtering arguments are provided' do
        let_it_be(:agent_1) { create(:cluster_agent, project: project) }
        let_it_be(:agent_2) { create(:cluster_agent, project: project) }

        it 'finds all agents' do
          expect(subject).to contain_exactly(agent_1, agent_2)
        end
      end

      context 'when has_vulnerabilities argument is provided' do
        let(:params) { { has_vulnerabilities: has_vulnerabilities } }
        let_it_be(:agent_with_vulnerabilities) do
          create(:cluster_agent, project: project, has_vulnerabilities: true)
        end

        let_it_be(:agent_without_vulnerabilities) do
          create(:cluster_agent, project: project, has_vulnerabilities: false)
        end

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

      context 'when has_remote_development_agent_config argument is provided' do
        let(:params) do
          { has_remote_development_agent_config: has_remote_development_agent_config }
        end

        let_it_be(:agent_with_remote_development_agent_config) do
          create(:ee_cluster_agent, :with_remote_development_agent_config,
            project: project)
        end

        let_it_be(:agent_without_remote_development_agent_config) do
          create(:ee_cluster_agent, project: project)
        end

        context 'when has_remote_development_agent_config is set to true' do
          let(:has_remote_development_agent_config) { true }

          it 'returns only agents with remote_development_agent_config' do
            expect(subject).to contain_exactly(agent_with_remote_development_agent_config)
          end
        end

        context 'when has_remote_development_agent_config is set to false' do
          let(:has_remote_development_agent_config) { false }

          it 'returns only agents without remote_development_agent_config' do
            expect(subject).to contain_exactly(agent_without_remote_development_agent_config)
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
