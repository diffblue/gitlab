# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > Batch comments', :js, :sidekiq_inline, feature_category: :code_review_workflow do
  include MergeRequestDiffHelpers
  include RepoHelpers

  let(:project) { create(:project, :public, :repository, merge_requests_author_approval: true) }
  let(:current_user) { project.owner }
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  before do
    create(:draft_note, merge_request: merge_request, author: current_user)

    sign_in(current_user)

    visit project_merge_request_path(merge_request.project, merge_request)

    wait_for_requests
  end

  context 'with approval' do
    context 'when user does not have permission to approve' do
      let(:current_user) { create(:user) }

      it 'does not allow user to approve' do
        click_button 'Finish review'

        expect(page).not_to have_selector('[data-testid="approve_merge_request"]')
      end
    end

    context 'when user has permission to approve' do
      it 'allows user to approve' do
        click_button 'Finish review'

        find('[data-testid="approve_merge_request"]').click
        click_button 'Submit review'

        wait_for_requests

        expect(page).to have_content('approved this merge request')
      end

      context 'when password is required for approval' do
        let(:project) do
          # rubocop:disable Layout/LineLength
          create(:project, :public, :repository, require_password_to_approve: true, merge_requests_author_approval: true)
          # rubocop:enable Layout/LineLength
        end

        it 'does not allow user to approve without password' do
          click_button 'Finish review'

          find('[data-testid="approve_merge_request"]').click
          click_button 'Submit review'

          wait_for_requests

          expect(page).to have_content('An error occurred while approving, please try again.')
        end

        it 'allows user to approve' do
          click_button 'Finish review'

          find('[data-testid="approve_merge_request"]').click
          fill_in(type: 'password', with: current_user.password)
          click_button 'Submit review'

          wait_for_requests

          expect(page).to have_content('approved this merge request')
        end
      end
    end
  end
end
