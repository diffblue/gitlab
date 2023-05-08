# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a workspace', feature_category: :remote_development do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { user } # NOTE: Some graphql spec helper methods rely on current_user to be set
  let_it_be(:project) { create(:project, :public, :in_group, :repository) }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }

  let(:desired_state) { RemoteDevelopment::Workspaces::States::RUNNING }

  let(:all_mutation_args) do
    {
      desired_state: desired_state,
      editor: 'webide',
      max_hours_before_termination: 24,
      cluster_agent_id: agent.to_global_id.to_s,
      project_id: project.to_global_id.to_s,
      devfile_ref: 'main',
      devfile_path: '.devfile.yaml'
    }
  end

  let(:mutation_args) { all_mutation_args }

  let(:mutation) do
    graphql_mutation(:workspace_create, mutation_args)
  end

  let(:expected_service_params) do
    params = all_mutation_args.except(:cluster_agent_id, :project_id)
    params[:agent] = agent
    params[:user] = current_user
    params[:project] = project
    params
  end

  let_it_be(:created_workspace, refind: true) { create(:workspace, user: user) }

  # noinspection RubyResolve
  let(:stub_service_payload) { { workspace: created_workspace } }
  let(:stub_service_response) do
    ServiceResponse.success(payload: stub_service_payload)
  end

  def mutation_response
    graphql_mutation_response(:workspace_create)
  end

  before do
    stub_licensed_features(remote_development: true)
    agent.project.add_developer(user)
    project.add_developer(user)
    allow_next_instance_of(
      ::RemoteDevelopment::Workspaces::CreateService
    ) do |service_instance|
      allow(service_instance).to receive(:execute).with(
        params: expected_service_params
      ) do
        stub_service_response
      end
    end
  end

  it 'creates the workspace' do
    post_graphql_mutation(mutation, current_user: user)

    expect_graphql_errors_to_be_empty

    # noinspection RubyResolve
    expect(mutation_response.fetch('workspace')['name']).to eq(created_workspace['name'])
  end

  context 'when there are service errors' do
    let(:stub_service_response) { ::ServiceResponse.error(message: 'some error', reason: :bad_request) }

    it_behaves_like 'a mutation that returns errors in the response', errors: ['some error']
  end

  context 'when required arguments are missing' do
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
