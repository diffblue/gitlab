# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Trains Skip Train Setting', :js, feature_category: :merge_trains do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    stub_licensed_features(merge_pipelines: true, merge_trains: true)
    sign_in(user)
  end

  context 'when visiting the project settings page' do
    before do
      visit project_settings_merge_requests_path(project)
      wait_for_requests
    end

    it 'is unchecked by default' do
      expect(find('#project_merge_trains_skip_train_allowed')).not_to be_checked
    end

    it 'can be enabled' do
      page.within('#project-merge-options') do
        check _('Allow skipping the merge train')
        expect(find('#project_merge_trains_skip_train_allowed')).to be_checked
      end

      click_button('Save changes')

      wait_for_requests

      expect(project.ci_cd_settings.merge_trains_skip_train_allowed).to eq(true)
    end
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(merge_trains_skip_train: false)
    end

    it 'does not show the checkbox' do
      expect(page).not_to have_checked_field('#project_merge_trains_skip_train_allowed')
    end
  end
end
