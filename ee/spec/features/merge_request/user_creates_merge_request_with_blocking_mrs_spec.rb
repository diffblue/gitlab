# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates a merge request with blocking MRs', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :repository) }
  let(:user) { project.first_owner }

  let(:mr_params) { { title: 'Some feature', source_branch: 'fix', target_branch: 'feature' } }

  before do
    sign_in(user)
  end

  context 'feature is enabled' do
    before do
      stub_licensed_features(blocking_merge_requests: true)
    end

    it 'creates a merge request with a blocking MR', :sidekiq_inline do
      other_mr = create(:merge_request)
      other_mr.target_project.team.add_maintainer(user)

      visit(project_new_merge_request_path(project, merge_request: mr_params))

      fill_in 'Merge request dependencies', with: other_mr.to_reference(full: true)
      click_button 'Create merge request'

      expect(page).to have_content('Depends on 1 merge request')
    end
  end

  context 'feature is disabled' do
    before do
      stub_licensed_features(blocking_merge_requests: false)
    end

    it 'does not show blocking MRs controls' do
      visit(project_new_merge_request_path(project, merge_request: mr_params))

      expect(page).not_to have_content('Merge request dependencies')
    end
  end
end
