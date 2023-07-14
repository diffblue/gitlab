# frozen_string_literal: true

require 'spec_helper'

# NOTE: This spec cannot use let_it_be because, because that doesn't work when using the `custom_repo` trait of
#       the project factory and subsequently modifying it, because it's a real on-disk repo at `tmp/tests/gitlab-test/`,
#       and any changes made to it are not reverted by let it be (even with reload). This means we also cannot use
#       these `let` declarations in a `before` context, so any mocking of them must occur in the examples themselves.

RSpec.describe ::RemoteDevelopment::Workspaces::Create::Main, :freeze_time, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let(:user) { create(:user) }
  let(:group) { create(:group, name: 'test-group').tap { |group| group.add_developer(user) } }
  let(:current_user) { user }
  let(:random_string) { 'abcdef' }
  let(:devfile_path) { '.devfile.yaml' }
  let(:devfile_fixture_name) { 'example.devfile.yaml' }
  let(:devfile_yaml) { read_devfile(devfile_fixture_name) }
  let(:processed_devfile) { YAML.safe_load(example_processed_devfile).to_h }
  let(:editor) { 'webide' }
  let(:workspace_root) { '/projects' }

  let(:project) do
    files = { devfile_path => devfile_yaml }
    create(:project, :public, :in_group, :custom_repo, path: 'test-project', files: files, namespace: group)
  end

  let(:agent) do
    create(:ee_cluster_agent, :with_remote_development_agent_config, project: project, created_by_user: user)
  end

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

  let(:value) { { current_user: current_user, params: params } }

  subject(:response) do
    described_class.main(value)
  end

  context 'when params are valid' do
    context 'when devfile is valid' do
      before do
        allow(SecureRandom).to receive(:alphanumeric) { random_string }
      end

      it 'creates a new workspace and returns success', :aggregate_failures do
        allow(project.repository).to receive_message_chain(:blob_at_branch, :data) { devfile_yaml }

        # NOTE: This example is structured and ordered to give useful and informative error messages in case of failures
        expect { subject }.to change { RemoteDevelopment::Workspace.count }.by(1)

        expect(response.fetch(:status)).to eq(:success)
        expect(response[:message]).to be_nil
        expect(response[:payload]).not_to be_nil
        expect(response[:payload][:workspace]).not_to be_nil

        workspace = response.fetch(:payload).fetch(:workspace)
        expect(workspace.user).to eq(user)
        expect(workspace.agent).to eq(agent)
        expect(workspace.desired_state).to eq(RemoteDevelopment::Workspaces::States::RUNNING)
        # noinspection RubyResolve
        expect(workspace.desired_state_updated_at).to eq(Time.current)
        expect(workspace.actual_state).to eq(RemoteDevelopment::Workspaces::States::CREATION_REQUESTED)
        expect(workspace.name).to eq("workspace-#{agent.id}-#{user.id}-#{random_string}")
        expect(workspace.namespace).to eq("gl-rd-ns-#{agent.id}-#{user.id}-#{random_string}")
        expect(workspace.editor).to eq('webide')
        expect(workspace.url).to eq(URI::HTTPS.build({
          host: "60001-#{workspace.name}.#{workspace.dns_zone}",
          query: {
            folder: "#{workspace_root}/#{project.path}"
          }.to_query
        }).to_s)
        # noinspection RubyResolve
        expect(workspace.devfile).to eq(devfile_yaml)

        actual_processed_devfile = YAML.safe_load(workspace.processed_devfile).to_h
        expect(actual_processed_devfile).to eq(processed_devfile)
      end
    end

    context 'when devfile is not valid', :aggregate_failures do
      let(:devfile_fixture_name) { 'example.invalid-components-entry-missing-devfile.yaml' }

      it 'does not create the workspace and returns error' do
        allow(project.repository).to receive_message_chain(:blob_at_branch, :data) { devfile_yaml }

        expect { subject }.not_to change { RemoteDevelopment::Workspace.count }

        expect(response).to eq({
          status: :error,
          message: "Workspace create post flatten devfile validation failed: No components present in devfile",
          reason: :bad_request
        })
      end
    end
  end

  context 'when params are invalid' do
    context 'when devfile is not found' do
      let(:devfile_path) { 'not-found.yaml' }

      it 'does not create the workspace and returns error', :aggregate_failures do
        allow(project.repository).to receive(:blob_at_branch).and_return(nil)

        expect { subject }.not_to change { RemoteDevelopment::Workspace.count }

        expect(response).to eq({
          status: :error,
          message: "Workspace create devfile load failed: Devfile could not be loaded from project",
          reason: :bad_request
        })
      end
    end

    context 'when agent has no associated config' do
      let(:agent) { create(:cluster_agent, name: "007") }

      it 'does not create the workspace and returns error' do
        # sanity check on fixture
        expect(agent.remote_development_agent_config).to be_nil

        expect { subject }.not_to change { RemoteDevelopment::Workspace.count }

        expect(response).to eq({
          status: :error,
          message: "Workspace create params validation failed: No RemoteDevelopmentAgentConfig found for agent '007'",
          reason: :bad_request
        })
      end
    end
  end
end
