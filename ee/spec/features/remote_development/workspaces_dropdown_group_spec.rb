# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Remote Development workspaces dropdown group', :api, :js, feature_category: :remote_development do
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

  let_it_be(:workspace) do
    create(:workspace, user: user, updated_at: 2.days.ago, project_id: project.id,
      actual_state: ::RemoteDevelopment::Workspaces::States::RUNNING,
      desired_state: ::RemoteDevelopment::Workspaces::States::RUNNING
    )
  end

  let(:workspaces_dropdown_selector) { '[data-testid="workspaces-dropdown-group"]' }

  before_all do
    group.add_developer(user)
  end

  before do
    allow(Gitlab::Kas).to receive(:verify_api_request).and_return(true)

    stub_licensed_features(remote_development: true)

    # rubocop:disable RSpec/AnyInstanceOf - It's NOT the next instance...
    allow_any_instance_of(Gitlab::Auth::AuthFinders)
      .to receive(:cluster_agent_token_from_authorization_token).and_return(agent_token)
    # rubocop:enable RSpec/AnyInstanceOf

    sign_in(user)
    wait_for_requests
  end

  shared_examples 'handles workspaces dropdown group visibility' do |feature_flag_enabled, feature_available, visible|
    before do
      stub_licensed_features(remote_development: feature_available)
      stub_feature_flags(remote_development_feature_flag: feature_flag_enabled)

      visit subject
    end

    context "when remote_development_feature_flag=#{feature_flag_enabled}" do
      context "when remote_development feature availability=#{feature_available}" do
        it 'does not display workspaces dropdown group' do
          click_button 'Edit'

          expect(page.has_css?(workspaces_dropdown_selector)).to be(visible)
        end
      end
    end
  end

  shared_examples 'views and manages workspaces in workspaces dropdown group' do
    it_behaves_like 'handles workspaces dropdown group visibility', true, true, true
    it_behaves_like 'handles workspaces dropdown group visibility', true, false, false
    it_behaves_like 'handles workspaces dropdown group visibility', false, true, false

    context 'when workspaces dropdown group is visible' do
      before do
        visit subject
        click_button 'Edit'
      end

      it 'allows navigating to the new workspace page' do
        click_link 'New workspace'

        # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
        expect(page).to have_current_path("#{new_remote_development_workspace_path}?project=#{project.full_path}")
        expect(page).to have_css('button', text: project.name_with_namespace)
      end

      it 'allows managing a user workspace' do
        # Asserts workspace is displayed
        expect(page).to have_content(workspace.name)

        # Asserts the workspace state is correctly displayed
        expect_workspace_state_indicator(workspace.actual_state)

        # Asserts that all workspaces actions are visible
        expect(page).to have_button('Restart')
        expect(page).to have_button('Stop')
        expect(page).to have_button('Terminate')

        click_button('Stop')

        # Ensures that the user can change a workspace state
        expect(page).to have_button('Stopping', disabled: true)
      end

      # noinspection RubyInstanceMethodNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
      def expect_workspace_state_indicator(state)
        indicator = page.find("[data-testid='workspace-state-indicator']")

        expect(indicator).to have_text(state)
      end
    end
  end

  describe 'when viewing project overview page' do
    let(:subject) { project_path(project) }

    it_behaves_like 'views and manages workspaces in workspaces dropdown group'
  end

  describe 'when viewing blob page' do
    # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
    let(:subject) { project_blob_path(project, "#{project.default_branch}/#{devfile_path}") }

    it_behaves_like 'views and manages workspaces in workspaces dropdown group'
  end
end
