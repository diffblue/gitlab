# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Disable Merge Trains Setting', :js, feature_category: :merge_trains do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before do
    stub_licensed_features(merge_pipelines: true, merge_trains: true)

    project.add_maintainer(user)
    sign_in(user)
  end

  shared_examples 'loads correct checkbox state' do
    it 'merge pipelines checkbox is always enabled' do
      expect(find('#project_merge_pipelines_enabled')).not_to be_disabled
    end

    it 'merge trains checkbox is enabled only when merge_pipelines_enabled is true' do
      expect(find('#project_merge_trains_enabled').disabled?).not_to eq(project.merge_pipelines_enabled)
    end
  end

  context 'when visiting the project settings page' do
    using RSpec::Parameterized::TableSyntax

    where(:merge_pipelines_setting, :merge_trains_setting) do
      true  | true
      true  | false
      false | true
      false | false
    end

    with_them do
      before do
        project.update!(merge_pipelines_enabled: merge_pipelines_setting, merge_trains_enabled: merge_trains_setting)
        visit project_settings_merge_requests_path(project)
        wait_for_requests
      end

      include_examples 'loads correct checkbox state'
    end
  end

  context 'when merge pipelines is enabled' do
    before do
      project.update!(merge_pipelines_enabled: true)
      visit project_settings_merge_requests_path(project)
      wait_for_requests
    end

    include_examples 'loads correct checkbox state'

    it "checking merge trains checkbox doesn't affect merge pipelines checkbox" do
      check('Enable merge trains')

      expect(find('#project_merge_trains_enabled')).to be_checked
      expect(find('#project_merge_pipelines_enabled')).not_to be_disabled
      expect(find('#project_merge_pipelines_enabled')).to be_checked
    end

    it 'unchecking merge pipelines checkbox disables merge trains checkbox' do
      uncheck('Enable merged results pipelines')

      expect(find('#project_merge_pipelines_enabled')).not_to be_checked
      expect(find('#project_merge_trains_enabled')).to be_disabled
    end

    it 'unchecking merge pipelines checkbox unchecks merge trains checkbox if it was previously checked' do
      check('Enable merge trains')
      uncheck('Enable merged results pipelines')

      expect(find('#project_merge_pipelines_enabled')).not_to be_checked
      expect(find('#project_merge_trains_enabled')).to be_disabled
      expect(find('#project_merge_trains_enabled')).not_to be_checked
    end
  end

  context 'when merge pipelines is disabled' do
    before do
      project.update!(merge_pipelines_enabled: false)
      visit project_settings_merge_requests_path(project)
      wait_for_requests
    end

    include_examples 'loads correct checkbox state'

    it 'checking merge pipelines checkbox enables merge trains checkbox' do
      check('Enable merged results pipelines')

      expect(find('#project_merge_pipelines_enabled')).to be_checked
      expect(find('#project_merge_trains_enabled')).not_to be_disabled
    end

    it 'checking merge pipelines checkbox should leave merge trains checkbox unchecked' do
      check('Enable merged results pipelines')

      expect(find('#project_merge_pipelines_enabled')).to be_checked
      expect(find('#project_merge_trains_enabled')).not_to be_checked
    end
  end

  context 'when both merge pipelines and merge trains are enabled' do
    before do
      project.update!(merge_pipelines_enabled: true, merge_trains_enabled: true)
      visit project_settings_merge_requests_path(project)
      wait_for_requests
    end

    include_examples 'loads correct checkbox state'

    it 'unchecking merge pipelines checkbox disables and unchecks merge trains checkbox' do
      uncheck('Enable merged results pipelines')

      expect(find('#project_merge_pipelines_enabled')).not_to be_checked
      expect(find('#project_merge_trains_enabled')).to be_disabled
      expect(find('#project_merge_trains_enabled')).not_to be_checked
    end

    it "unchecking merge trains checkbox doesn't affect merge pipelines checkbox" do
      uncheck('Enable merge trains')

      expect(find('#project_merge_trains_enabled')).not_to be_checked
      expect(find('#project_merge_pipelines_enabled')).not_to be_disabled
      expect(find('#project_merge_pipelines_enabled')).to be_checked
    end
  end
end
