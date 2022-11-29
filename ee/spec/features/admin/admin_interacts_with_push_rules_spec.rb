# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin interacts with push rules", feature_category: :source_code_management do
  include StubENV

  let_it_be(:user) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(user)
    gitlab_enable_admin_mode_sign_in(user)
  end

  push_rules_with_titles = {
    reject_unsigned_commits: "Reject unsigned commits",
    commit_committer_check: "Reject unverified users"
  }

  push_rules_with_titles.each do |rule_attr, title|
    context "when #{rule_attr} is unlicensed" do
      before do
        stub_licensed_features(rule_attr => false)

        visit(admin_push_rule_path)
      end

      it { expect(page).not_to have_content(title) }
    end

    context "when #{rule_attr} is licensed" do
      before do
        stub_licensed_features(rule_attr => true)

        visit(admin_push_rule_path)
      end

      it { expect(page).to have_content(title) }
    end
  end

  context "when creating push rule" do
    before do
      visit(admin_push_rule_path)
    end

    it "creates new rule" do
      fill_in("Require expression in commit messages", with: "my_string")
      click_button("Save push rules")

      expect(page).to have_selector("input[value='my_string']")
    end
  end
end
