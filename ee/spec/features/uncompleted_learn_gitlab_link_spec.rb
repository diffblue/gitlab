# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Uncompleted learn gitlab link', :feature, :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, name: LearnGitlab::Project::PROJECT_NAME, namespace: user.namespace) }
  let_it_be(:namespace) { project.namespace }

  context 'change_continuous_onboarding_link_urls experiment' do
    before do
      allow_next_instance_of(LearnGitlab::Project) do |learn_gitlab|
        allow(learn_gitlab).to receive(:available?).and_return(true)
      end
    end

    context 'when control' do
      before do
        create(:onboarding_progress,
          namespace: namespace,
          issue_created_at: Date.yesterday,
          git_write_at: Date.yesterday,
          pipeline_created_at: Date.yesterday,
          merge_request_created_at: Date.yesterday,
          user_added_at: Date.yesterday,
          security_scan_enabled_at: Date.yesterday
        )

        stub_experiments(change_continuous_onboarding_link_urls: :control)
      end

      it 'renders correct completed sections' do
        sign_in(user)
        visit namespace_project_learn_gitlab_path(namespace, project)

        expect_completed_section('Create an issue')
        expect_completed_section('Create or import a repository')
        expect_completed_section('Set up CI/CD')
        expect_completed_section('Submit a merge request')
        expect_completed_section('Invite your colleagues')
        expect_completed_section('Run a Security scan using CI/CD')
      end
    end

    context 'when candidate' do
      before do
        create(:onboarding_progress, namespace: namespace)
        stub_experiments(change_continuous_onboarding_link_urls: :candidate)
      end

      it 'renders correct links' do
        sign_in(user)
        visit namespace_project_learn_gitlab_path(namespace, project)
        issue_link = find_link('Create an issue')

        expect_correct_candidate_link(issue_link, project_issues_path(project))
        expect_correct_candidate_link(find_link('Create or import a repository'), project_path(project))
        expect_correct_candidate_link(find_link('Set up CI/CD'), project_pipelines_path(project))
        expect_correct_candidate_link(find_link('Submit a merge request'), project_merge_requests_path(project))
        expect_correct_candidate_link(find_link('Invite your colleagues'), URI(project_members_url(project)).path)
        expect_correct_candidate_link(find_link('Run a Security scan using CI/CD'), project_security_configuration_path(project))

        issue_link.click
        expect(page).to have_current_path(project_issues_path(project))
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
