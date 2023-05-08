# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::Create::CreateProcessor, :freeze_time, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  describe '#process' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public, :in_group, :repository) }
    let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
    let(:random_string) { 'abcdef' }
    let(:devfile_path) { '.devfile.yaml' }
    let(:fake_devfile_name) { 'example.devfile.yaml' }
    let(:fake_devfile) { read_devfile(fake_devfile_name) }
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

    subject do
      described_class.new
    end

    context 'when params are valid' do
      context 'when devfile is valid' do
        before do
          allow(SecureRandom).to receive(:alphanumeric) { random_string }
          allow(project.repository).to receive_message_chain(:blob_at_branch, :data) { fake_devfile }
          allow_next_instance_of(RemoteDevelopment::Workspaces::Create::DevfileProcessor) do |processor|
            allow(processor)
              .to receive(:process).with(
                devfile: fake_devfile,
                editor: editor,
                project: project,
                workspace_root: workspace_root
              ).and_return(example_processed_devfile)
          end
        end

        it 'creates a new workspace' do
          payload, error = subject.process(params: params)
          expect(error).to be_nil

          workspace = payload.fetch(:workspace)
          expect(workspace).not_to be_nil
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
          expect(workspace.devfile).to eq(fake_devfile)
        end
      end

      context 'when devfile is not valid' do
        let(:fake_devfile_name) { 'example.invalid-no-components-devfile.yaml' }

        before do
          allow(project.repository).to receive_message_chain(:blob_at_branch, :data) { fake_devfile }
        end

        it 'returns an error' do
          payload, error = subject.process(params: params)
          expect(payload).to be_nil
          expect(error.message).to eq('Invalid devfile: No components present in the devfile')
          expect(error.reason).to eq(:bad_request)
        end
      end
    end

    context 'when params are invalid' do
      context 'when devfile is not found' do
        let(:devfile_path) { 'not-found.yaml' }

        before do
          allow(project.repository).to receive(:blob_at_branch).and_return(nil)
        end

        it 'returns an error' do
          payload, error = subject.process(params: params)
          expect(payload).to be_nil
          expect(error.message).to eq('Devfile not found in project')
          expect(error.reason).to eq(:bad_request)
        end
      end

      context 'when agent has no associated config' do
        let_it_be(:agent) { create(:cluster_agent) }

        it 'returns an error' do
          # sanity check on fixture
          expect(agent.remote_development_agent_config).to be_nil

          payload, error = subject.process(params: params)
          expect(payload).to be_nil
          expect(error.message).to eq("No RemoteDevelopmentAgentConfig found for agent '#{agent.name}'")
          expect(error.reason).to eq(:bad_request)
        end
      end
    end
  end
end
