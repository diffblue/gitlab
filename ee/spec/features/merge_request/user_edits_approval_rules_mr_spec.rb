# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User edits MR with approval rules', :js, feature_category: :code_review_workflow do
  include FeatureApprovalHelper
  include ListboxInputHelper

  include_context 'with project with approval rules'

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:approver) { create(:user) }
  let_it_be(:mr_rule_names) { %w[foo lorem ipsum] }
  let_it_be(:mr_rules) do
    mr_rule_names.map do |name|
      create(
        :approval_merge_request_rule,
        merge_request: merge_request,
        approvals_required: 1,
        name: name,
        users: [approver]
      )
    end
  end

  let(:modal_selector) { '#mr-edit-approvals-create-modal' }

  def page_rule_names
    page.all('.js-approval-rules table .js-name')
  end

  before do
    project.update!(disable_overriding_approvers_per_merge_request: false)
    stub_licensed_features(multiple_approval_rules: true)

    sign_in(author)
    visit(edit_project_merge_request_path(project, merge_request))

    wait_for_requests
  end

  it "shows approval rules" do
    click_button 'Approval rules'

    names = page_rule_names.map(&:text)

    expect(names).to eq(mr_rule_names)
  end

  it "allows user to create approval rule" do
    click_button 'Approval rules'

    rule_name = "Custom Approval Rule"

    click_button "Add approval rule"

    within_fieldset('Rule name') do
      fill_in with: rule_name
    end

    listbox_input approver.name, from: modal_selector

    find("#{modal_selector} button", text: 'Add approval rule').click
    wait_for_requests

    expect(page_rule_names.last).to have_text(rule_name)
  end

  context 'with public group' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:public_group) { create(:group, :public) }

    before do
      stub_feature_flags(permit_all_shared_groups_for_approval: false)

      group_project = create(:project, :public, :repository, namespace: group)
      group_project_merge_request = create(:merge_request, source_project: group_project)
      group.add_developer(author)

      visit(edit_project_merge_request_path(group_project, group_project_merge_request))

      wait_for_requests

      click_button 'Approval rules'
      click_button "Add approval rule"
    end

    it "with empty search, does not show public group" do
      open_approver_select

      expect(page).not_to have_selector('.gl-listbox-item', text: public_group.name)
    end

    it "with non-empty search, shows public group" do
      open_approver_select

      within(modal_selector) do
        find('[data-testid="listbox-search-input"]').fill_in(with: public_group.name)
      end
      wait_for_requests

      expect(page).to have_selector('.gl-listbox-item', text: public_group.name)
    end
  end

  context 'feature is disabled' do
    before do
      stub_licensed_features(merge_request_approvers: false)

      visit(edit_project_merge_request_path(project, merge_request))
    end

    it 'cannot see the approval rules input' do
      expect(page).not_to have_content('Approval rules')
    end
  end
end
