# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Uncompleted learn gitlab link', :feature, :js, feature_category: :onboarding do
  include Spec::Support::Helpers::Features::InviteMembersModalHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group).tap { |g| g.add_owner(user) } }
  let_it_be(:project) { create(:project, namespace: namespace) }

  before do
    allow_next_instance_of(Onboarding::LearnGitlab) do |learn_gitlab|
      allow(learn_gitlab).to receive(:onboarding_and_available?).and_return(true)
    end
  end

  context 'with completed links' do
    before do
      yesterday = Date.yesterday
      create(
        :onboarding_progress,
        namespace: namespace,
        issue_created_at: yesterday,
        git_write_at: yesterday,
        pipeline_created_at: yesterday,
        merge_request_created_at: yesterday,
        user_added_at: yesterday,
        security_scan_enabled_at: yesterday
      )
    end

    it 'renders correct completed sections' do
      sign_in(user)
      visit namespace_project_learn_gitlab_path(namespace, project)

      expect_completed_section('Create an issue')
      expect_completed_section('Create a repository')
      expect_completed_section("Set up your first project's CI/CD")
      expect_completed_section('Submit a merge request (MR)')
      expect_completed_section('Invite your colleagues')
      expect_completed_section('Run a Security scan using CI/CD')
    end
  end

  context 'without completion progress' do
    before_all do
      create(:onboarding_progress, namespace: namespace)
    end

    it 'renders correct links and navigates to project issues' do
      sign_in(user)
      visit namespace_project_learn_gitlab_path(namespace, project)

      issue_link = find_link('Create an issue')

      expect_correct_candidate_link(issue_link, project_issues_path(project))
      expect_correct_candidate_link(find_link('Create a repository'), project_path(project))
      expect_correct_candidate_link(find_link('Invite your colleagues'), '#')
      expect_correct_candidate_link(find_link("Set up your first project's CI/CD"), project_pipelines_path(project))
      expect_correct_candidate_link(find_link('Start a free trial of GitLab Ultimate'), project_issues_path(project, 2))
      expect_correct_candidate_link(find_link('Add code owners'), project_issues_path(project, 10))
      expect_correct_candidate_link(find_link('Enable require merge approvals'), project_issues_path(project, 11))
      expect_correct_candidate_link(find_link('Submit a merge request (MR)'), project_merge_requests_path(project))
      expect_correct_candidate_link(
        find_link('Run a Security scan using CI/CD'),
        project_security_configuration_path(project)
      )

      issue_link.click
      expect(page).to have_current_path(project_issues_path(project))
    end

    context 'with invite_for_help_continuous_onboarding candidate experience' do
      before do
        stub_experiments(invite_for_help_continuous_onboarding: :candidate)

        sign_in(user)
        visit namespace_project_learn_gitlab_path(namespace, project)
      end

      it 'launches invite modal when invite is clicked' do
        click_link('Invite your colleagues')

        page.within invite_modal_selector do
          expect(page).to have_content("You're inviting members to the #{project.name} project")
        end
      end
    end
  end

  def expect_completed_section(text)
    expect(page).to have_no_link(text)
    expect(page).to have_css('.gl-text-green-500', text: text)
  end

  def expect_correct_candidate_link(link, path)
    expect(link['href']).to match(path)
    expect(link['data-testid']).to eq('uncompleted-learn-gitlab-link')
  end
end
