# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User merges with Push Rules', :js, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository, push_rule: push_rule) }
  let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: user, title: 'Bug NS-04') }

  before do
    project.add_maintainer(user)
  end

  context 'commit message is invalid' do
    let(:push_rule) { create(:push_rule, :commit_message) }

    before do
      sign_in user
      visit_merge_request(merge_request)
    end

    it 'displays error message after merge request is clicked' do
      click_merge_button

      expect(page).to have_content("Commit message does not follow the pattern '#{push_rule.commit_message_regex}'")
    end
  end

  context 'author email is invalid' do
    let(:push_rule) { create(:push_rule, :author_email) }

    before do
      sign_in user
      visit_merge_request(merge_request)
    end

    it 'displays error message after merge request is clicked' do
      click_merge_button

      expect(page).to have_content("Author's commit email '#{user.email}' does not follow the pattern '#{push_rule.author_email_regex}'")
    end
  end

  def visit_merge_request(merge_request)
    visit project_merge_request_path(merge_request.project, merge_request)
  end

  def click_merge_button
    page.within('.mr-state-widget') do
      click_button 'Merge'
    end
  end
end
