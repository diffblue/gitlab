# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User views merge request with blocking merge requests", :js do
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
    page.within('.mr-widget-section') do
      expect(page).to have_content('Merge blocked: all merge request dependencies must be merged or closed.')
    end
  end

  context 'merged blocking merge request' do
    let(:other_mr) { create(:merge_request, state: :merged) }

    it 'enables merge button when blocking merge request is merged' do
      page.within('.mr-widget-section') do
        expect(page).not_to have_content('Merge blocked: all merge request dependencies must be merged or closed.')
      end
    end
  end
end
