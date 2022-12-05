# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ClusterAgent'] do
  it 'includes the ee specific fields' do
    expect(described_class).to have_graphql_fields(
      :vulnerability_images
    ).at_least
  end

  describe 'vulnerability_images' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:cluster_agent) { create(:cluster_agent, project: project) }
    let_it_be(:vulnerability) do
      create(:vulnerability, :with_cluster_image_scanning_finding,
        agent_id: cluster_agent.id, project: project, report_type: :cluster_image_scanning)
    end

    let_it_be(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            clusterAgent(name: "#{cluster_agent.name}") {
              vulnerabilityImages {
                nodes {
                  name
                }
              }
            }
          }
        }
      )
    end

    before do
      stub_licensed_features(security_dashboard: true)

      project.add_developer(user)
    end

    subject(:vulnerability_images) do
      result = GitlabSchema.execute(query, context: { current_user: current_user }).as_json
      result.dig('data', 'project', 'clusterAgent', 'vulnerabilityImages', 'nodes', 0)
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      it { is_expected.to be_nil }
    end

    context 'when user is logged in' do
      let(:current_user) { user }

      it 'returns a list of container images reported for vulnerabilities' do
        expect(vulnerability_images).to eq('name' => 'alpine:3.7')
      end
    end
  end
end
