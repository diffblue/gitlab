# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User comments on a merge request', :js, feature_category: :code_review_workflow do
  include RepoHelpers

  let(:group) { create(:group, :public) }
  let!(:epic) { create(:epic, group: group) }
  let(:project) { create(:project, :repository, group: group) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(epics: true)
    project.add_maintainer(user)
    sign_in(user)
    visit(merge_request_path(merge_request))
  end

  it 'handles esc key correctly when atwho is active' do
    page.within('.js-main-target-form') do
      fill_in('note[note]', with: 'comment 1')
      click_button('Comment')
    end

    wait_for_requests

    page.within('.note') do
      click_button('Reply to comment')
      fill_in('note[note]', with: '&')
      send_keys :escape
    end

    wait_for_requests
    expect(page.html).not_to include('Are you sure you want to cancel creating this comment?')
  end
end
