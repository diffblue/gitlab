# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'approaching seat count threshold alert', :saas, :js, feature_category: :subscription_management do
  include SubscriptionPortalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }

  let_it_be(:gitlab_subscription) do
    create(
      :gitlab_subscription,
      namespace: group,
      plan_code: Plan::ULTIMATE,
      seats: 20,
      max_seats_used: 18,
      max_seats_used_changed_at: 1.day.ago
    )
  end

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)

    stub_subscription_request_seat_usage(true)
  end

  shared_examples 'a hidden alert' do
    it 'does not appear on the group page' do
      visit group_path(group)

      expect_alert_to_be_hidden
    end

    it 'does not appear on the project page' do
      visit project_path(project)

      expect_alert_to_be_hidden
    end
  end

  context 'when the user is not authenticated' do
    before do
      group.add_owner(user)
    end

    it_behaves_like 'a hidden alert'
  end

  context 'user is not eligible for the alert' do
    before do
      group.add_developer(user)

      sign_in(user)
    end

    it_behaves_like 'a hidden alert'
  end

  context 'when the user is eligible for the alert' do
    before do
      group.add_owner(user)

      sign_in(user)
    end

    it 'shows the dismissible alert on the group page' do
      visit group_path(group)

      expect(page).to have_content("#{group.name} is approaching the limit of available seats")
      expect(page)
        .to have_content(
          "Your subscription has #{gitlab_subscription.seats - gitlab_subscription.max_seats_used} out of" \
          " #{gitlab_subscription.seats} seats remaining."
        )
      expect(page).to have_link('View seat usage', href: usage_quotas_path(group, anchor: 'seats-quota-tab'))

      find('[data-testid="approaching-seat-count-threshold-alert-dismiss"]').click

      expect_alert_to_be_hidden

      wait_for_requests
      # reload the page to ensure it stays dismissed
      visit group_path(group)

      expect_alert_to_be_hidden
    end

    it 'shows the dismissible alert on the project page' do
      visit project_path(project)

      expect(page).to have_content("#{group.name} is approaching the limit of available seats")
      expect(page)
        .to have_content(
          "Your subscription has #{gitlab_subscription.seats - gitlab_subscription.max_seats_used} out of" \
          " #{gitlab_subscription.seats} seats remaining."
        )
      expect(page).to have_link('View seat usage', href: usage_quotas_path(group, anchor: 'seats-quota-tab'))

      find('[data-testid="approaching-seat-count-threshold-alert-dismiss"]').click

      expect_alert_to_be_hidden

      wait_for_requests
      # reload the page to ensure it stays dismissed
      visit project_path(project)

      expect_alert_to_be_hidden
    end
  end

  def expect_alert_to_be_hidden
    expect(page).not_to have_content("#{group.name} is approaching the limit of available seats")
    expect(page).not_to have_link('View seat usage', href: usage_quotas_path(group, anchor: 'seats-quota-tab'))
  end
end
