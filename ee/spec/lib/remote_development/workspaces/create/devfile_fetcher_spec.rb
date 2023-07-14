# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::Create::DevfileFetcher, feature_category: :remote_development do
  include ResultMatchers

  include_context 'with remote development shared fixtures'

  subject(:result) do
    described_class.fetch(value)
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :in_group, :repository) }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let(:random_string) { 'abcdef' }
  let(:devfile_path) { '.devfile.yaml' }
  let(:devfile_fixture_name) { 'example.devfile.yaml' }
  let(:devfile_yaml) { read_devfile(devfile_fixture_name) }
  let(:editor) { 'webide' }
  let(:workspace_root) { '/projects' }
  let(:params) do
    {
      agent: agent,
      user: user,
      project: project,
      editor: editor,
      max_hours_before_termination: 24,
      desired_state: RemoteDevelopment::Workspaces::States::RUNNING,
      devfile_ref: 'main',
      devfile_path: devfile_path
    }
  end

  let(:value) { { params: params } }

  before do
    allow(project.repository).to receive_message_chain(:blob_at_branch, :data) { devfile_yaml }
  end

  context 'when params are valid' do
    let(:devfile) { YAML.safe_load(devfile_yaml) }

    it 'returns an ok Result containing the original params and the devfile_yaml_string' do
      expect(result).to eq(
        Result.ok({
          params: params,
          devfile_yaml: devfile_yaml,
          devfile: devfile
        })
      )
    end
  end

  context 'when params are invalid' do
    context 'when agent has no associated config' do
      let_it_be(:agent) { create(:cluster_agent) }

      it 'returns an err Result containing error details' do
        # sanity check on fixture
        expect(agent.remote_development_agent_config).to be_nil

        expect(result).to be_err_result do |message|
          expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceCreateParamsValidationFailed)
          message.context => { details: String => error_details }
          expect(error_details).to eq("No RemoteDevelopmentAgentConfig found for agent '#{agent.name}'")
        end
      end
    end

    context 'when devfile is not found' do
      let(:devfile_path) { 'not-found.yaml' }

      before do
        allow(project.repository).to receive(:blob_at_branch).and_return(nil)
      end

      it 'returns an err Result containing error details' do
        expect(result).to be_err_result do |message|
          expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceCreateDevfileLoadFailed)
          message.context => { details: String => error_details }
          expect(error_details).to eq("Devfile could not be loaded from project")
        end
      end
    end

    context 'when devfile YAML cannot be loaded' do
      let(:devfile_yaml) { "invalid: yaml: boom" }

      it 'returns an err Result containing error details' do
        expect(result).to be_err_result do |message|
          expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceCreateDevfileYamlParseFailed)
          message.context => { details: String => error_details }
          expect(error_details).to match(/Devfile YAML could not be parsed: .*mapping values are not allowed/i)
        end
      end
    end
  end
end
