# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User creates a merge request", :js, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include CookieHelper

  let(:approver) { create(:user) }
  let(:project) do
    create(:project, :repository, merge_requests_template: template_text)
  end

  let(:template_text) { "This merge request should contain the following." }
  let(:title) { "Some feature" }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  before do
    project.add_maintainer(user)
    project.add_maintainer(user2)
    project.add_maintainer(approver)
    sign_in(user)
    set_cookie('new-actions-popover-viewed', 'true')

    stub_licensed_features(admin_merge_request_approvers_rules: true)
    create(:approval_project_rule, project: project, users: [approver])

    visit(project_new_merge_request_path(project))
  end

  it "creates a merge request" do
    allow_next_instance_of(Gitlab::AuthorityAnalyzer) do |instance|
      allow(instance).to receive(:calculate).and_return([user2])
    end

    find(".js-source-branch").click

    find('.gl-listbox-search-input').set('fix')

    wait_for_requests

    find('.gl-new-dropdown-item-text-wrapper', text: 'fix', match: :first).click

    find(".js-target-branch").click

    find('.gl-listbox-search-input').set('feature')

    wait_for_requests

    find('.gl-new-dropdown-item-text-wrapper', text: 'feature', match: :first).click

    click_button("Compare branches")

    expect(find_field("merge_request_description").value).to eq(template_text)

    click_button 'Approval rules'

    page.within('.js-approval-rules') do
      expect(page).to have_css("img[alt=\"#{approver.name}\"]")
    end

    # TODO: Fix https://gitlab.com/gitlab-org/gitlab/issues/11527
    # page.within(".suggested-approvers") do
    #   expect(page).to have_content(user2.name)
    # end
    #
    # click_link(user2.name)
    #
    # page.within("ul.approver-list") do
    #   expect(page).to have_content(user2.name)
    # end

    fill_in("Title", with: title)
    click_button("Create merge request")

    wait_for_requests

    page.within(".js-issuable-actions") do
      click_link("Edit", match: :first)
    end

    # page.within("ul.approver-list") do
    #   expect(page).to have_content(user2.name)
    # end
  end
end
