# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin interacts with merge requests approvals settings' do
  include StubENV

  let_it_be(:user) { create(:admin) }
  let_it_be(:project) { create(:project, creator: user) }

  before do
    sign_in(user)
    gitlab_enable_admin_mode_sign_in(user)

    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    allow(License).to receive(:feature_available?).and_return(true)

    visit(admin_push_rule_path)
  end

  it 'updates instance-level merge request approval settings and enforces project-level ones', :js do
    page.within('.merge-request-approval-settings') do
      check 'Prevent MR approvals by author.'
      check 'Prevent MR approvals from users who make commits to the MR.'
      check _('Prevent users from modifying MR approval rules in projects and merge requests.')
      click_button('Save changes')
    end

    visit(admin_push_rule_path)

    expect(find_field('Prevent MR approvals by author.')).to be_checked
    expect(find_field('Prevent MR approvals from users who make commits to the MR.')).to be_checked
    expect(find_field(_('Prevent users from modifying MR approval rules in projects and merge requests.'))).to be_checked

    visit edit_project_path(project)

    page.within('[data-testid="merge-request-approval-settings"]') do
      expect(find('[data-testid="prevent-author-approval"] > input')).to be_disabled.and be_checked
      expect(find('[data-testid="prevent-committers-approval"] > input')).to be_disabled.and be_checked
      expect(find('[data-testid="prevent-mr-approval-rule-edit"] > input')).to be_disabled.and be_checked
    end
  end
end
