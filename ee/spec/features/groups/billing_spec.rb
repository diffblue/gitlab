# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Billing', :js, :saas do
  include StubRequests
  include SubscriptionPortalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:bronze_plan) { create(:bronze_plan) }

  def formatted_date(date)
    date.strftime("%B %-d, %Y")
  end

  def subscription_table
    '.subscription-table'
  end

  before_all do
    group.add_owner(user)
  end

  before do
    stub_application_setting(check_namespace_plan: true)

    sign_in(user)
  end

  shared_examples 'hides search settings' do
    it 'does not have search settings' do
      visit group_billings_path(group)

      expect(page).not_to have_field(placeholder: SearchHelpers::INPUT_PLACEHOLDER)
    end
  end

  context 'when CustomersDot is available' do
    before do
      stub_eoa_eligibility_request(group.id)
      stub_billing_plans(group.id, plan)
    end

    context 'with a free plan' do
      let(:plan) { 'free' }

      let!(:subscription) do
        create(:gitlab_subscription, namespace: group, hosted_plan: nil, seats: 15)
      end

      it_behaves_like 'hides search settings'

      it 'shows the proper title and subscription data' do
        visit group_billings_path(group)

        expect(page).to have_content("#{group.name} is currently using the Free Plan")
        within subscription_table do
          expect(page).to have_content("start date #{formatted_date(subscription.start_date)}")
          expect(page).not_to have_link("Manage")
        end
      end
    end

    context 'with a paid plan' do
      let(:plan) { 'bronze' }

      let_it_be(:subscription) do
        create(:gitlab_subscription, end_date: Date.today + 14.days, namespace: group, hosted_plan: bronze_plan, seats: 15)
      end

      it_behaves_like 'hides search settings'

      it 'shows the proper title and subscription data' do
        extra_seats_url = "#{EE::SUBSCRIPTIONS_URL}/gitlab/namespaces/#{group.id}/extra_seats"
        renew_url = "#{EE::SUBSCRIPTIONS_URL}/gitlab/namespaces/#{group.id}/renew"

        visit group_billings_path(group)

        expect(page).to have_content("#{group.name} is currently using the Bronze Plan")
        within subscription_table do
          expect(page).to have_content("start date #{formatted_date(subscription.start_date)}")
          expect(page).to have_link("Manage", href: EE::SUBSCRIPTIONS_MANAGE_URL)
          expect(page).to have_link("Add seats", href: extra_seats_url)
          expect(page).to have_link("Renew", href: renew_url)
          expect(page).to have_link("See usage", href: group_usage_quotas_path(group, anchor: 'seats-quota-tab'))
        end
      end

      context 'when gitlab subscription has end date more than 15 days' do
        before do
          subscription.update!(end_date: Date.tomorrow + 15.days)
        end

        it 'does not display renew button' do
          renew_url = "#{EE::SUBSCRIPTIONS_URL}/gitlab/namespaces/#{group.id}/renew"

          visit group_billings_path(group)

          within subscription_table do
            expect(page).not_to have_link("Renew", href: renew_url)
          end
        end
      end
    end

    context 'with a legacy paid plan' do
      let(:plan) { 'bronze' }

      let!(:subscription) do
        create(:gitlab_subscription, end_date: 1.week.ago, namespace: group, hosted_plan: bronze_plan, seats: 15)
      end

      it 'shows the proper title and subscription data' do
        visit group_billings_path(group)

        expect(page).to have_content("#{group.name} is currently using the Bronze Plan")
        within subscription_table do
          expect(page).to have_link("Manage", href: EE::SUBSCRIPTIONS_MANAGE_URL)
        end
      end
    end
  end

  context 'when CustomersDot is unavailable' do
    before do
      stub_billing_plans(group.id, plan, raise_error: 'Connection refused')
    end

    let(:plan) { 'bronze' }

    let_it_be(:subscription) do
      create(:gitlab_subscription, namespace: group, hosted_plan: bronze_plan, seats: 15)
    end

    it 'renders an error page' do
      visit group_billings_path(group)

      expect(page).to have_content("Subscription service outage")
    end
  end
end
