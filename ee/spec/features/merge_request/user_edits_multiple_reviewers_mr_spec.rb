# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User edits MR with multiple reviewers' do
  include_context 'merge request edit context'

  before do
    stub_licensed_features(multiple_merge_request_reviewers: true)
  end

  it_behaves_like 'multiple reviewers merge request', 'updates', 'Save changes'

  context 'user approval rules', :js do
    let(:rule_name) { 'some-custom-rule' }
    let!(:mr_rule) { create(:approval_merge_request_rule, merge_request: merge_request, users: [user], name: rule_name, approvals_required: 1 )}

    it 'is not shown in assignee dropdown' do
      find('.js-assignee-search').click
      wait_for_requests

      page.within '.dropdown-menu-assignee' do
        expect(page).not_to have_content(rule_name)
      end
    end

    it 'is shown in reviewer dropdown' do
      find('.js-reviewer-search').click
      wait_for_requests

      page.within '.dropdown-menu-reviewer' do
        expect(page).to have_content(rule_name)
      end
    end

    describe 'escapes rule name' do
      let(:rule_name) { '<img src="" />' }

      it 'is shown in reviewer dropdown' do
        find('.js-reviewer-search').click
        wait_for_requests

        page.within '.dropdown-menu-reviewer' do
          expect(page).to have_content(rule_name)
        end
      end
    end
  end

  context 'code owner approval rules', :js do
    let(:code_owner_pattern) { '*' }
    let!(:code_owner_rule) {create(:code_owner_rule, name: code_owner_pattern, merge_request: merge_request, users: [user])}
    let!(:mr_rule) { create(:approval_merge_request_rule, merge_request: merge_request )}

    it 'displays "Code Owner" text in reviewer dropdown' do
      find('.js-reviewer-search').click
      wait_for_requests

      page.within '.dropdown-menu-reviewer' do
        expect(page).to have_content('Code Owner')
        expect(page).not_to have_content(code_owner_pattern)
      end
    end
  end
end
