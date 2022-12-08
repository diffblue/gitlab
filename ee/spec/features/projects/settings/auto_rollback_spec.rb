# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Automatic Deployment Rollbacks', feature_category: :release_orchestration do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when the user is not authorised' do
    it 'renders 404 page' do
      visit project_settings_ci_cd_path(project)

      expect(page).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'the auto rollback feature is not available' do
    it 'does not render the Automatic Deployment Rollbacks checkbox' do
      project.add_maintainer(user)
      visit project_settings_ci_cd_path(project)

      expect(page).to have_gitlab_http_status(:ok)
      expect(page).not_to have_selector('#auto-rollback-settings')
    end
  end

  context 'when project does not have a license for auto_rollback feature' do
    before do
      stub_licensed_features(auto_rollback: false)
    end

    it_behaves_like 'the auto rollback feature is not available'
  end

  context 'when project has a license for auto_rollback feature' do
    before do
      stub_licensed_features(auto_rollback: true)
      project.add_maintainer(user)
      visit project_settings_ci_cd_path(project)
    end

    it 'checks the auto rollback checkbox when the checkbox is checked' do
      expect(page.find('#project_auto_rollback_enabled')).not_to be_checked

      within('#auto-rollback-settings') do
        check('project_auto_rollback_enabled')
        click_on('Save changes')
      end
      visit project_settings_ci_cd_path(project) # Reload from database

      expect(page.find('#project_auto_rollback_enabled')).to be_checked
    end
  end

  context 'when the checkbox is checked' do
    before do
      stub_licensed_features(auto_rollback: true)
      project.add_maintainer(user)
      project.update!(auto_rollback_enabled: true)
      visit project_settings_ci_cd_path(project)
    end

    it 'unchecks the auto rollback checkbox' do
      expect(page.find('#project_auto_rollback_enabled')).to be_checked

      within('#auto-rollback-settings') do
        uncheck('project_auto_rollback_enabled')
        click_on('Save changes')
      end
      visit project_settings_ci_cd_path(project) # Reload from database

      expect(page.find('#project_auto_rollback_enabled')).not_to be_checked
    end
  end
end
