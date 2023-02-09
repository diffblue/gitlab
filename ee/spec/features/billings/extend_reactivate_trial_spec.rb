# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Billings > Extend / Reactivate Trial', :js, :saas, feature_category: :billing_and_payments do
  include SubscriptionPortalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:plan) { create(:ultimate_plan) }
  let_it_be(:plans_data) do
    Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/gitlab_com_plans.json'))).map do |data|
      data.deep_symbolize_keys
    end
  end

  let(:initial_trial_end_date) { Date.current }
  let(:extended_or_reactivated_trial_end_date) { initial_trial_end_date + 30.days }

  before do
    group.add_owner(user)

    allow(Gitlab).to receive(:com?).and_return(true)
    stub_signing_key
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_feature_flags(allow_extend_reactivate_trial: true)
    stub_billing_plans(nil)
    stub_full_request("#{EE::SUBSCRIPTIONS_GITLAB_PLANS_URL}?plan=#{plan.name}&namespace_id=#{group.id}")
      .to_return(status: 200, body: plans_data.to_json)
    stub_full_request("#{EE::SUBSCRIPTIONS_GITLAB_PLANS_URL}?plan=free&namespace_id=#{group.id}")
      .to_return(status: 200, body: plans_data.to_json)
    stub_full_request("#{EE::SUBSCRIPTIONS_URL}/trials/extend_reactivate_trial", method: :put)
      .to_return(status: 200)
    stub_subscription_management_data(group.id)
    sign_in(user)
  end

  shared_examples 'a non-extendable trial' do
    before do
      visit group_billings_path(group)
    end

    it 'does not display the "Extend trial" button' do
      expect(page).not_to have_button('Extend trial')
    end
  end

  shared_examples 'an extendable trial' do
    before do
      allow_next_instance_of(GitlabSubscriptions::ExtendReactivateTrialService) do |service|
        group.gitlab_subscription.update!(trial_extension_type: GitlabSubscription.trial_extension_types[:extended],
                                          end_date: initial_trial_end_date,
                                          trial_ends_on: extended_or_reactivated_trial_end_date)
      end
      visit group_billings_path(group)
    end

    it 'extends the trial' do
      expect(page).to have_content("trial will expire after #{initial_trial_end_date}")

      within '.billing-plan-header' do
        click_button('Extend trial')
      end

      within '[data-testid="extend-reactivate-trial-modal"]' do
        click_button('Extend trial')
      end

      wait_for_requests

      expect(page).to have_content("trial will expire after #{extended_or_reactivated_trial_end_date}")
      expect(page).not_to have_button('Extend trial')
    end
  end

  context 'with paid subscription' do
    context 'when expired' do
      let_it_be(:subscription) { create(:gitlab_subscription, :expired, hosted_plan: plan, namespace: group) }

      it_behaves_like 'a non-extendable trial'

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(allow_extend_reactivate_trial: false)
        end

        it_behaves_like 'a non-extendable trial'
      end
    end

    context 'when not expired' do
      let_it_be(:subscription) { create(:gitlab_subscription, hosted_plan: plan, namespace: group) }

      it_behaves_like 'a non-extendable trial'
    end
  end

  context 'without a subscription' do
    it_behaves_like 'a non-extendable trial'
  end

  context 'with active trial near the expiration date' do
    let(:initial_trial_end_date) { Date.tomorrow }

    let_it_be(:subscription) { create(:gitlab_subscription, :active_trial, trial_ends_on: Date.tomorrow, hosted_plan: plan, namespace: group) }

    it_behaves_like 'an extendable trial'
  end

  context 'with extended trial' do
    let_it_be(:subscription) { create(:gitlab_subscription, :extended_trial, hosted_plan: plan, namespace: group) }

    it_behaves_like 'a non-extendable trial'
  end

  context 'with reactivated trial' do
    let_it_be(:subscription) { create(:gitlab_subscription, :reactivated_trial, hosted_plan: plan, namespace: group) }

    it_behaves_like 'a non-extendable trial'
  end

  context 'with expired trial' do
    let(:initial_trial_end_date) { Date.current.advance(days: -1) }

    let_it_be(:subscription) { create(:gitlab_subscription, :expired_trial, hosted_plan: plan, namespace: group) }

    it_behaves_like 'a non-extendable trial'
  end
end
