# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard operations', :js, feature_category: :shared do
  let_it_be(:user) { create(:user) }

  before do
    stub_licensed_features(operations_dashboard: true)
  end

  it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :operations_path, :operations_dashboard

  it 'displays information about the last pipeline to an authenticated developer on the project' do
    project = create(:project, :repository, name: 'Great Project')
    pipeline = create(:ci_pipeline, project: project, sha: project.commit.sha, status: :running)
    project.add_developer(user)
    user.update!(ops_dashboard_projects: [project])
    sign_in(user)

    visit operations_path

    expect(page).to have_text(project.name)
    expect(page).to have_text(pipeline.ref)
    expect(page).to have_text(pipeline.short_sha)
    expect(page).to have_text('Alerts')
    expect(page).to have_text(pipeline.status)
  end

  context 'when opened on gitlab.com', :saas do
    before do
      stub_application_setting(check_namespace_plan: true)
    end

    it 'masks projects without valid license' do
      ultimate_group = create(:group)
      bronze_group = create(:group)

      create(:gitlab_subscription, :ultimate, namespace: ultimate_group)
      create(:gitlab_subscription, :bronze, namespace: bronze_group)

      ultimate_project = create(:project, :repository, namespace: ultimate_group, name: 'Ultimate Project')
      bronze_project = create(:project, :repository, namespace: bronze_group, name: 'Bronze Project')
      public_project = create(:project, :repository, :public, namespace: bronze_group, name: 'Public Bronze Project')

      ultimate_pipeline = create(:ci_pipeline, project: ultimate_project, sha: ultimate_project.commit.sha, status: :running)
      bronze_pipeline = create(:ci_pipeline, project: bronze_project, sha: bronze_project.commit.sha, status: :running)
      public_pipeline = create(:ci_pipeline, project: public_project, sha: public_project.commit.sha, status: :running)

      ultimate_project.add_developer(user)
      bronze_group.add_developer(user)

      user.update!(ops_dashboard_projects: [ultimate_project, bronze_project, public_project])
      sign_in(user)

      visit operations_path

      bronze_card = project_card(bronze_project)
      ultimate_card = project_card(ultimate_project)
      public_card = project_card(public_project)

      assert_masked(bronze_card, bronze_project, bronze_pipeline, bronze_group)
      assert_available(ultimate_card, ultimate_project, ultimate_pipeline)
      assert_available(public_card, public_project, public_pipeline)
    end

    def project_card(project)
      page.find('.js-dashboard-project', text: "#{project.namespace.name} / #{project.name}")
    end

    def assert_available(card, project, pipeline)
      expect(card).to have_text(project.name)
      expect(card).to have_text(pipeline.ref)
      expect(card).to have_text(pipeline.short_sha)
      expect(card).to have_text('Alerts')
      expect(card).to have_text(pipeline.status)
    end

    def assert_masked(card, project, pipeline, group)
      expect(card).to have_text(project.name)
      expect(card).to have_text("To see this project's operational details, contact an owner of group #{group.path} to upgrade the plan. You can also remove the project from the dashboard.")
      expect(card).not_to have_text(pipeline.ref)
      expect(card).not_to have_text(pipeline.short_sha)
      expect(card).not_to have_text('Alerts')
      expect(card).not_to have_text(pipeline.status)
    end
  end
end
