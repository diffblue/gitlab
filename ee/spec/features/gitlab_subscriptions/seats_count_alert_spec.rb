# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Display approaching seats count threshold alert', :saas, :js do
  let_it_be(:user) { create(:user) }

  shared_examples_for 'a hidden alert' do
    it 'does not show the alert' do
      visit visit_path

      expect(page).not_to have_content("#{group.name} is approaching the limit of available seats")
      expect(page).not_to have_link('View seat usage', href: usage_quotas_path(group, anchor: 'seats-quota-tab'))
    end
  end

  shared_examples_for 'a visible alert' do
    it 'shows the alert' do
      visit visit_path

      expect(page).to have_content("#{group.name} is approaching the limit of available seats")
      expect(page).to have_content("Your subscription has #{gitlab_subscription.seats - gitlab_subscription.seats_in_use} out of #{gitlab_subscription.seats} seats remaining. Even if you reach the number of seats in your subscription, you can continue to add users, and GitLab will bill you for the overage.")
      expect(page).to have_link('View seat usage', href: usage_quotas_path(group, anchor: 'seats-quota-tab'))
    end
  end

  shared_examples_for 'a dismissed alert' do
    context 'when alert was dismissed' do
      before do
        visit visit_path

        find('body.page-initialised [data-testid="approaching-seats-count-threshold-alert-dismiss"]').click
      end

      it_behaves_like 'a hidden alert'
    end
  end

  context 'when conditions not met' do
    let_it_be(:group) { create(:group) }
    let_it_be(:visit_path) { group_path(group) }

    context 'when logged out' do
      it_behaves_like 'a hidden alert'
    end

    context 'when logged in owner' do
      before do
        group.add_owner(user)
        sign_in(user)
      end

      it_behaves_like 'a hidden alert'
    end
  end
end
