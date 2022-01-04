# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Slack application' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { :developer }
  let(:integration) { create(:gitlab_slack_application_integration, project: project) }
  let(:slack_application_form_path) { edit_project_integration_path(project, integration) }

  before do
    gitlab_sign_in(user)
    project.add_maintainer(user)

    create(:slack_integration, integration: integration)

    allow(Gitlab).to receive(:com?).and_return(true)
    allow(Gitlab::CurrentSettings).to receive(:slack_app_enabled).and_return(true)
  end

  it 'I can edit slack integration' do
    visit slack_application_form_path

    within '.service-settings' do
      click_link 'Edit'
    end

    fill_in 'slack_integration_alias', with: 'alias-edited'
    click_button 'Save changes'

    expect(page).to have_content('The project alias was updated successfully')

    within '.service-settings' do
      expect(page).to have_content('alias-edited')
    end
  end
end
