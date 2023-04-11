# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Request > User views blocked MR', :js, feature_category: :code_review_workflow do
  let(:block) { create(:merge_request_block) }
  let(:blocking_mr) { block.blocking_merge_request }
  let(:blocked_mr) { block.blocked_merge_request }
  let(:project) { blocked_mr.target_project }
  let(:user) { create(:user) }

  let(:merge_button) { find('[data-testid="merge-button"]') }

  def click_expand_button
    find('[data-testid="report-section-expand-button"]').click
  end

  before do
    project.add_developer(user)

    sign_in(user)
  end

  context 'blocking merge requests are disabled' do
    before do
      stub_licensed_features(blocking_merge_requests: false)
    end

    it 'is mergeable' do
      visit project_merge_request_path(project, blocked_mr)

      expect(page).to have_button('Merge', exact: true, disabled: false)
    end
  end

  context 'blocking merge requests are enabled' do
    before do
      stub_licensed_features(blocking_merge_requests: true)
    end

    context 'blocking MR is not visible' do
      it 'is not mergeable' do
        visit project_merge_request_path(project, blocked_mr)

        expect(page).to have_content('Depends on 1 merge request')
        expect(page).not_to have_button('Merge', exact: true)

        click_expand_button

        expect(page).not_to have_content(blocking_mr.title)
        expect(page).to have_content("1 merge request that you don't have access to")
      end
    end

    context 'blocking MR is visible' do
      before do
        blocking_mr.target_project.add_developer(user)
      end

      it 'is not mergeable' do
        visit project_merge_request_path(project, blocked_mr)

        expect(page).to have_content('Depends on 1 merge request')
        expect(page).not_to have_button('Merge', exact: true)

        click_expand_button

        expect(page).to have_content(blocking_mr.title)
      end
    end
  end
end
