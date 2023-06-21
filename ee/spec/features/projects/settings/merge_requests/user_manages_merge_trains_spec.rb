# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EE > Projects > Settings > Merge requests > User manages merge trains', :js,
  feature_category: :merge_trains do
  let_it_be(:project, refind: true) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:merge_pipelines) { true }
  let(:merge_trains) { true }

  before do
    stub_licensed_features(merge_pipelines: merge_pipelines, merge_trains: merge_trains)

    project.update!(merge_pipelines_enabled: true)
    project.add_maintainer(user)
    sign_in(user)

    visit project_settings_merge_requests_path(project)
  end

  it 'sees unchecked merge trains checkbox' do
    wait_for_requests

    expect(page.find('#project_merge_trains_enabled')).not_to be_checked
  end

  context 'when user enabled the checkbox' do
    before do
      wait_for_requests

      check('Enable merge trains')
    end

    it 'sees enabled merge trains checkbox' do
      expect(page.find('#project_merge_trains_enabled')).to be_checked
    end
  end

  context 'when license is insufficient' do
    let(:merge_pipelines) { false }
    let(:merge_trains) { false }

    it 'does not see the checkbox' do
      expect(page).not_to have_css('#project_merge_trains_enabled')
    end
  end
end
