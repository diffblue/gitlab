# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Blocked deployment job page', :js, feature_category: :continuous_integration do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:build) { create(:ci_build, :manual, environment: 'production', project: project) }
  let(:environment) { create(:environment, name: 'production', project: project) }

  before do
    stub_licensed_features(protected_environments: true)

    create(:protected_environment, project: project, name: 'production', required_approval_count: 1)
    create(:deployment, :blocked, project: project, environment: environment, deployable: build)

    project.add_developer(user)
    sign_in(user)

    visit(project_job_path(project, build))
  end

  it 'displays a button linking to the environments page' do
    expect(page).to have_text('Waiting for approvals')
    expect(page).to have_link('View environment details page', href: project_environment_path(project, environment))

    find("[data-testid='job-empty-state-action']").click

    expect(page).to have_current_path(project_environment_path(project, environment))
  end
end
