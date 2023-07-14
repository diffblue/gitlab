# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::Create::Creator, feature_category: :remote_development do
  include ResultMatchers

  include_context 'with remote development shared fixtures'

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :public, :in_group, :repository) }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let(:random_string) { 'abcdef' }
  let(:devfile_path) { '.devfile.yaml' }
  let(:devfile_yaml) { example_devfile }
  let(:processed_devfile) { YAML.safe_load(example_flattened_devfile) }
  let(:desired_state) { RemoteDevelopment::Workspaces::States::RUNNING }
  let(:processed_devfile_yaml) { YAML.safe_load(example_processed_devfile) }

  let(:editor) { 'webide' }
  let(:workspace_root) { '/projects' }
  let(:params) do
    {
      agent: agent,
      user: user,
      project: project,
      editor: editor,
      max_hours_before_termination: 24,
      desired_state: desired_state,
      devfile_ref: 'main',
      devfile_path: devfile_path
    }
  end

  let(:value) do
    {
      params: params,
      current_user: user,
      devfile_yaml: devfile_yaml,
      processed_devfile: processed_devfile,
      volume_mounts: {
        data_volume: {
          name: "gl-workspace-data",
          path: workspace_root
        }
      }
    }
  end

  subject(:result) do
    described_class.create(value) # rubocop:disable Rails/SaveBang
  end

  context 'when workspace create is successful' do
    before do
      allow(SecureRandom).to receive(:alphanumeric) { random_string }
    end

    it 'creates the workspace and returns ok result containing successful message with created workspace' do
      expect { subject }.to change { project.workspaces.count }

      expect(result).to be_ok_result do |message|
        expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceCreateSuccessful)
        message.context => { workspace: RemoteDevelopment::Workspace => workspace }
        expect(workspace).to eq(project.workspaces.last)
      end
    end
  end

  context 'when workspace create fails' do
    let(:desired_state) { 'InvalidDesiredState' }

    it 'does not create the workspace and returns an error result containing a failed message with model errors' do
      expect { subject }.not_to change { project.workspaces.count }

      expect(result).to be_err_result do |message|
        expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceCreateFailed)
        message.context => { errors: ActiveModel::Errors => errors }
        expect(errors.full_messages).to match([/desired state/i])
      end
    end
  end
end
