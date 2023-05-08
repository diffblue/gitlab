# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Remote Development workspaces', :api, :js, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'
  include_context 'file upload requests helpers'

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'test-group') }
  let_it_be(:devfile_path) { '.devfile.yaml' }

  let_it_be(:project) do
    files = { devfile_path => example_devfile }
    create(:project, :public, :in_group, :custom_repo, path: 'test-project', files: files, namespace: group)
  end

  let_it_be(:agent) do
    create(:ee_cluster_agent, :with_remote_development_agent_config, project: project, created_by_user: user)
  end

  let_it_be(:agent_token) { create(:cluster_agent_token, agent: agent, created_by_user: user) }

  let(:reconcile_url) { capybara_url(api('/internal/kubernetes/modules/remote_development/reconcile', user)) }

  before do
    stub_licensed_features(remote_development: true)

    group.add_developer(user)
    allow(Gitlab::Kas).to receive(:verify_api_request).and_return(true)

    # rubocop:disable RSpec/AnyInstanceOf - It's NOT the next instance...
    allow_any_instance_of(Gitlab::Auth::AuthFinders)
      .to receive(:cluster_agent_token_from_authorization_token) { agent_token }
    # rubocop:enable RSpec/AnyInstanceOf

    sign_in(user)
    wait_for_requests
  end

  describe 'workspaces' do
    context 'when creating' do
      it 'creates a workspace' do
        # Tips:
        # use live_debug to pause when WEBDRIVER_HEADLESS=0
        # live_debug

        # NAVIGATE TO WORKSPACES PAGE

        # noinspection RubyResolve
        visit remote_development_workspaces_path
        wait_for_requests

        # CREATE WORKSPACE

        click_link 'New workspace', match: :first
        click_button 'Select a project'
        page.find("li[data-testid='listbox-item-#{project.full_path}']").click
        wait_for_requests
        select agent.name, from: 'Select cluster agent'
        click_button 'Create workspace'

        # We look for the project GID because that's all we know about the workspace at this point. For the new UI,
        # we will have to either expose this as a field on the new workspaces UI, or else come up
        # with some more clever finder to assert on the workspace showing up in the list after a refresh.
        page.find('td', text: project.name_with_namespace)

        # GET NAME AND NAMESPACE OF NEW WORKSPACE
        workspaces = RemoteDevelopment::Workspace.all.to_a
        expect(workspaces.length).to eq(1)
        workspace = workspaces[0]
        id = workspace.id
        name = workspace.name
        namespace = workspace.namespace

        # ASSERT ON NEW WORKSPACE IN LIST
        page.find('td', text: name)

        # ASSERT WORKSPACE STATE BEFORE POLLING NEW STATES
        expect_workspace_state_indicator('Creating')

        # ASSERT TERMINATE BUTTON IS AVAILABLE
        expect(page).to have_button('Terminate')

        # SIMULATE FIRST POLL FROM AGENTK TO PICK UP NEW WORKSPACE
        simulate_first_poll(id: id, name: name, namespace: namespace)

        # SIMULATE SECOND POLL FROM AGENTK TO UPDATE WORKSPACE TO RUNNING STATE

        simulate_second_poll(id: id, name: name, namespace: namespace)

        # ASSERT WORKSPACE SHOWS RUNNING STATE IN UI AND UPDATES URL
        expect_workspace_state_indicator(RemoteDevelopment::Workspaces::States::RUNNING)
        expect(page).to have_selector('a', text: workspace.url)

        # ASSERT ACTION BUTTONS ARE CORRECT FOR RUNNING STATE
        expect(page).to have_button('Restart')
        expect(page).to have_button('Stop')
        expect(page).to have_button('Terminate')

        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409780 - Add state transition to TERMINATED
      end

      def simulate_first_poll(id:, name:, namespace:)
        # SIMULATE FIRST POLL REQUEST FROM AGENTK TO GET NEW WORKSPACE

        reconcile_post_response = simulate_agentk_reconcile_post(workspace_agent_infos: [])

        # ASSERT ON RESPONSE TO FIRST POLL REQUEST CONTAINING NEW WORKSPACE

        expect(reconcile_post_response.code).to eq(HTTP::Status::CREATED)
        infos = Gitlab::Json.parse(reconcile_post_response.body).deep_symbolize_keys[:workspace_rails_infos]
        expect(infos.length).to eq(1)
        info = infos.first

        expect(info.fetch(:name)).to eq(name)
        expect(info.fetch(:namespace)).to eq(namespace)
        expect(info.fetch(:desired_state)).to eq(RemoteDevelopment::Workspaces::States::RUNNING)
        expect(info.fetch(:actual_state)).to eq(RemoteDevelopment::Workspaces::States::CREATION_REQUESTED)
        expect(info.fetch(:deployment_resource_version)).to be_nil

        expected_config_to_apply = create_config_to_apply(
          workspace_id: id,
          workspace_name: name,
          workspace_namespace: namespace,
          agent_id: agent.id,
          owning_inventory: "#{name}-workspace-inventory",
          started: true
        )

        config_to_apply = info.fetch(:config_to_apply)
        expect(config_to_apply).to eq(expected_config_to_apply)
      end

      def simulate_second_poll(id:, name:, namespace:)
        # SIMULATE SECOND POLL REQUEST FROM AGENTK TO UPDATE WORKSPACE TO RUNNING STATE

        resource_version = '1'
        workspace_agent_info = create_workspace_agent_info(
          workspace_id: id,
          workspace_name: name,
          workspace_namespace: namespace,
          agent_id: agent.id,
          owning_inventory: "#{name}-workspace-inventory",
          resource_version: resource_version,
          previous_actual_state: RemoteDevelopment::Workspaces::States::STARTING,
          current_actual_state: RemoteDevelopment::Workspaces::States::RUNNING,
          workspace_exists: false
        )
        reconcile_post_response =
          simulate_agentk_reconcile_post(workspace_agent_infos: [workspace_agent_info])

        # ASSERT ON RESPONSE TO SECOND POLL REQUEST

        expect(reconcile_post_response.code).to eq(HTTP::Status::CREATED)
        infos = Gitlab::Json.parse(reconcile_post_response.body).deep_symbolize_keys[:workspace_rails_infos]
        expect(infos.length).to eq(1)
        info = infos.first

        expect(info.fetch(:name)).to eq(name)
        expect(info.fetch(:namespace)).to eq(namespace)
        expect(info.fetch(:desired_state)).to eq(RemoteDevelopment::Workspaces::States::RUNNING)
        expect(info.fetch(:actual_state)).to eq(RemoteDevelopment::Workspaces::States::RUNNING)
        expect(info.fetch(:deployment_resource_version)).to eq(resource_version)
        expect(info.fetch(:config_to_apply)).to be_nil
      end

      def expect_workspace_state_indicator(state)
        expect(page).to have_selector("svg[data-testid='workspace-state-indicator'][title='#{state}']")
      end

      def simulate_agentk_reconcile_post(workspace_agent_infos:)
        post_params = {
          update_type: 'partial',
          workspace_agent_infos: workspace_agent_infos
        }

        # Note: HTTParty doesn't handle empty arrays right, so we have to be explicit with content type and send JSON.
        #       See https://github.com/jnunemaker/httparty/issues/494
        HTTParty.post(
          reconcile_url,
          headers: { 'Content-Type' => 'application/json' },
          body: post_params.compact.to_json
        )
      end
    end
  end
end
