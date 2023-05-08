# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating a workspace', feature_category: :remote_development do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { user } # NOTE: Some graphql spec helper methods rely on current_user to be set
  let_it_be(:project) { create(:project, :public, :in_group, :repository) }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let_it_be(:workspace, refind: true) do
    create(
      :workspace,
      agent: agent,
      project: project,
      user: user,
      desired_state: RemoteDevelopment::Workspaces::States::RUNNING,
      editor: 'webide'
    )
  end

  let(:all_mutation_args) do
    {
      id: workspace.to_global_id.to_s,
      desired_state: RemoteDevelopment::Workspaces::States::STOPPED
    }
  end

  let(:mutation_args) { { id: global_id_of(workspace), desired_state: RemoteDevelopment::Workspaces::States::STOPPED } }
  let(:mutation) { graphql_mutation(:workspace_update, mutation_args) }
  let(:expected_service_params) { all_mutation_args.except(:id) }
  let(:stub_service_payload) { { workspace: workspace } }
  let(:stub_service_response) do
    ServiceResponse.success(payload: stub_service_payload)
  end

  def mutation_response
    graphql_mutation_response(:workspace_update)
  end

  before do
    stub_licensed_features(remote_development: true)
    agent.project.add_developer(user)
    project.add_developer(user)
    allow_next_instance_of(
      ::RemoteDevelopment::Workspaces::UpdateService
    ) do |service_instance|
      allow(service_instance).to receive(:execute).with(
        workspace: workspace,
        params: expected_service_params
      ) do
        stub_service_response
      end
    end
  end

  it 'updates the workspace' do
    post_graphql_mutation(mutation, current_user: user)

    expect_graphql_errors_to_be_empty

    expect(mutation_response.fetch('workspace')['name']).to eq(workspace['name'])
  end

  context 'when there are service errors' do
    let(:stub_service_response) { ::ServiceResponse.error(message: 'some error', reason: :bad_request) }

    it_behaves_like 'a mutation that returns errors in the response', errors: ['some error']
  end

  context 'when some required arguments are missing' do
    let(:mutation_args) { all_mutation_args.except(:desired_state) }

    it 'returns error about required argument' do
      post_graphql_mutation(mutation, current_user: user)

      expect_graphql_errors_to_include(/provided invalid value for desiredState \(Expected value to not be null\)/)
    end
  end

  context 'when the user cannot create a workspace for the project' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation on an unauthorized resource'
  end

  context 'when remote_development feature is unlicensed' do
    before do
      stub_licensed_features(remote_development: false)
    end

    it_behaves_like 'a mutation that returns top-level errors' do
      let(:match_errors) { include(/'remote_development' licensed feature is not available/) }
    end
  end

  context 'when remote_development_feature_flag feature flag is disabled' do
    before do
      stub_feature_flags(remote_development_feature_flag: false)
    end

    it_behaves_like 'a mutation that returns top-level errors' do
      let(:match_errors) { include(/'remote_development_feature_flag' feature flag is disabled/) }
    end
  end
end
