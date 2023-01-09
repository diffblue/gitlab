# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User edits merge request with blocking MRs", :js, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.target_project }
  let(:user) { merge_request.target_project.first_owner }

  let(:other_mr) { create(:merge_request) }

  before do
    sign_in(user)
  end

  context 'feature is enabled' do
    before do
      stub_licensed_features(blocking_merge_requests: true)
    end

    context 'user can see the other MR' do
      let(:blocked_text) { 'Depends on 1 merge request' }

      before do
        other_mr.target_project.team.add_developer(user)
      end

      it 'can add the other MR' do
        visit edit_project_merge_request_path(project, merge_request)

        fill_in 'Merge request dependencies', with: other_mr.to_reference(full: true)

        click_button 'Save changes'

        expect(page).to have_content(blocked_text)
      end

      it 'can see and remove an existing blocking MR' do
        create(:merge_request_block, blocking_merge_request: other_mr, blocked_merge_request: merge_request)

        visit edit_project_merge_request_path(project, merge_request)

        expect(page).to have_content(other_mr.to_reference(full: true))

        click_button "Remove #{other_mr.to_reference(full: true)}"
        click_button 'Save changes'

        expect(page).not_to have_content(blocked_text)
        expect(page).not_to have_content(other_mr.to_reference(full: true))
      end
    end

    context 'user cannot see the other MR' do
      it 'cannot add the other MR' do
        visit edit_project_merge_request_path(project, merge_request)

        fill_in 'Merge request dependencies', with: other_mr.to_reference(full: true)

        click_button 'Save changes'

        expect(page).not_to have_content('Depends on 1 merge request')
      end

      it 'sees the existing MR as hidden and can remove it' do
        create(:merge_request_block, blocking_merge_request: other_mr, blocked_merge_request: merge_request)

        visit edit_project_merge_request_path(project, merge_request)

        expect(page).to have_content('1 inaccessible merge request')

        click_button 'Remove 1 inaccessible merge request'
        click_button 'Save changes'

        expect(page).not_to have_content('Depends on 1 merge request')
        expect(page).not_to have_content(other_mr.to_reference(full: true))
      end
    end
  end

  context 'feature is disabled' do
    before do
      stub_licensed_features(blocking_merge_requests: false)
    end

    it 'cannot see the blocking MR controls' do
      visit edit_project_merge_request_path(project, merge_request)

      expect(page).not_to have_content('Blocking merge requests')
    end
  end
end
