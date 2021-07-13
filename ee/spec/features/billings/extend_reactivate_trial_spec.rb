# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Billings > Extend / Reactivate Trial', :js do
  include SubscriptionPortalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:plan) { create(:free_plan) }
  let_it_be(:plans_data) do
    Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/gitlab_com_plans.json'))).map do |data|
      data.deep_symbolize_keys
    end
  end

  before do
    group.add_owner(user)
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_full_request("#{EE::SUBSCRIPTIONS_URL}/gitlab_plans?plan=#{plan.name}&namespace_id=#{group.id}")
      .to_return(status: 200, body: plans_data.to_json)
    stub_full_request("#{EE::SUBSCRIPTIONS_URL}/trials/extend_reactivate_trial", method: :put)
      .to_return(status: 200)
    sign_in(user)
    stub_feature_flags(allow_extend_reactivate_trial: true)
  end

  shared_examples 'a non-reactivatable trial' do
    before do
      visit group_billings_path(group)
    end

    it 'does not display the "Reactivate trial" button' do
      expect(page).not_to have_button('Reactivate trial')
    end
  end

  shared_examples 'a non-extendable trial' do
    before do
      visit group_billings_path(group)
    end

    it 'does not display the "Extend trial" button' do
      expect(page).not_to have_button('Extend trial')
    end
  end

  shared_examples 'a reactivatable trial' do
    before do
      visit group_billings_path(group)
    end

    it 'reactivates trial' do
      click_button('Reactivate trial')

      within '[data-testid="extend-reactivate-trial-modal"]' do
        click_button('Reactivate trial')
      end

      expect(page).to have_content('Your trial has been reactivated')
      expect(page).not_to have_button('Reactivate trial')
    end
  end

  shared_examples 'an extendable trial' do
    before do
      visit group_billings_path(group)
    end

    it 'extends the trial' do
      click_button('Extend trial')

      within '[data-testid="extend-reactivate-trial-modal"]' do
        click_button('Extend trial')
      end

      expect(page).to have_content('Your trial has been extended')
      expect(page).not_to have_button('Extend trial')
    end
  end

  context 'with paid subscription' do
    context 'when expired' do
      let_it_be(:subscription) { create(:gitlab_subscription, :expired, hosted_plan: plan, namespace: group) }

      it_behaves_like 'a non-reactivatable trial'
      it_behaves_like 'a non-extendable trial'

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(allow_extend_reactivate_trial: false)
        end

        it_behaves_like 'a non-reactivatable trial'
        it_behaves_like 'a non-extendable trial'
      end
    end

    context 'when not expired' do
      let_it_be(:subscription) { create(:gitlab_subscription, hosted_plan: plan, namespace: group) }

      it_behaves_like 'a non-reactivatable trial'
      it_behaves_like 'a non-extendable trial'
    end
  end

  context 'without a subscription' do
    it_behaves_like 'a non-reactivatable trial'
    it_behaves_like 'a non-extendable trial'
  end

  context 'with active trial near the expiration date' do
    let_it_be(:subscription) { create(:gitlab_subscription, :active_trial, trial_ends_on: Date.tomorrow, hosted_plan: plan, namespace: group) }

    it_behaves_like 'an extendable trial'
    it_behaves_like 'a non-reactivatable trial'
  end

  context 'with extended trial' do
    let_it_be(:subscription) { create(:gitlab_subscription, :extended_trial, hosted_plan: plan, namespace: group) }

    it_behaves_like 'a non-extendable trial'
    it_behaves_like 'a non-reactivatable trial'
  end

  context 'with reactivated trial' do
    let_it_be(:subscription) { create(:gitlab_subscription, :reactivated_trial, hosted_plan: plan, namespace: group) }

    it_behaves_like 'a non-extendable trial'
    it_behaves_like 'a non-reactivatable trial'
  end

  context 'with expired trial' do
    let_it_be(:subscription) { create(:gitlab_subscription, :expired_trial, hosted_plan: plan, namespace: group) }

    it_behaves_like 'a reactivatable trial'
    it_behaves_like 'a non-extendable trial'
  end
end
