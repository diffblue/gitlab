# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Request sidebar', feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :repository, :public, group: group) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  context 'when epics available' do
    before do
      stub_licensed_features(epics: true)
    end

    it 'does not show epics in MR sidebar' do
      visit project_merge_request_path(project, merge_request)

      expect(page).not_to have_selector('.block.epic')
    end
  end

  context 'when epics unavailable' do
    before do
      stub_licensed_features(epics: false)
    end

    it 'does not show epics promotion in MR sidebar' do
      visit project_merge_request_path(project, merge_request)

      expect(page).not_to have_selector('.js-epics-sidebar-callout')
    end
  end
end
