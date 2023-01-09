# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User views merge request with blocking merge requests", :js, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:user) { merge_request.target_project.first_owner }

  let(:other_mr) { create(:merge_request) }

  before do
    stub_licensed_features(blocking_merge_requests: true)

    other_mr.target_project.team.add_developer(user)
    create(:merge_request_block, blocking_merge_request: other_mr, blocked_merge_request: merge_request)

    sign_in(user)

    visit merge_request_path(merge_request)
  end

  it 'disables merge button when blocking merge request is open' do
    expect(page).to have_content('Merge blocked: you can only merge after the above items are resolved.')
  end

  context 'merged blocking merge request' do
    let(:other_mr) { create(:merge_request, state: :merged) }

    it 'enables merge button when blocking merge request is merged' do
      page.within('.mr-state-widget') do
        expect(page).not_to have_content('Merge blocked: all merge request dependencies must be merged.')
      end
    end
  end
end
