# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Contextual sidebar', :saas, :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) do
    create(:group).tap do |record|
      record.add_owner(user)
    end
  end

  let_it_be(:subscription) do
    create(:gitlab_subscription, :active_trial, namespace: group)
  end

  before do
    stub_application_setting(check_namespace_plan: true)
    allow_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService, plan: :free) do |instance|
      allow(instance).to receive(:execute).and_return([{ 'code' => 'ultimate', 'id' => 'ultimate-plan-id' }])
    end

    sign_in(user)
  end

  context 'when in group' do
    before do
      visit group_path(group)
    end

    it 'shows the popover for the trial status widget' do
      expect(page).not_to have_selector('.js-sidebar-collapsed')

      find('#trial-status-sidebar-widget').hover

      expect(page).to have_content("We hope you’re enjoying the features of GitLab")
    end
  end

  context 'when in project' do
    let_it_be(:project) { create(:project, namespace: group) }

    before do
      visit project_path(project)
    end

    it 'shows the popover for the trial status widget' do
      expect(page).not_to have_selector('.js-sidebar-collapsed')

      find('#trial-status-sidebar-widget').hover

      expect(page).to have_content("We hope you’re enjoying the features of GitLab")
    end
  end
end
