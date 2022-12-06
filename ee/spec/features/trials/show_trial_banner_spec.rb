# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Show trial banner', :js, feature_category: :purchase do
  include SubscriptionPortalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:ultimate_plan) { create(:ultimate_plan) }

  before do
    stub_signing_key
    stub_application_setting(check_namespace_plan: true)
    allow(Gitlab).to receive(:com?).and_return(true).at_least(:once)
    stub_billing_plans(nil)

    sign_in(user)
  end

  context "when user's trial is active" do
    before do
      create(:gitlab_subscription, :active_trial, namespace: user.namespace, hosted_plan: ultimate_plan)
      stub_billing_plans(user.namespace_id)
      stub_subscription_management_data(user.namespace_id)
    end

    it 'renders congratulations banner for user in profile billing page' do
      visit profile_billings_path(trial: true)

      expect(page).to have_content('Congratulations, your free trial is activated.')
    end
  end

  context "when group's trial is active" do
    before do
      group.add_owner(user)
      create(:gitlab_subscription, :active_trial, namespace: group, hosted_plan: ultimate_plan)
      stub_billing_plans(group.id)
      stub_subscription_management_data(group.id)
    end

    it 'renders congratulations banner for group in group details page' do
      visit group_path(group, trial: true)

      expect(find('[data-testid="trial-alert"]').text).to have_content('Congratulations, your free trial is activated.')
    end

    it 'does not render congratulations banner for group in group billing page' do
      visit group_billings_path(group, trial: true)

      expect(page).not_to have_content('Congratulations, your free trial is activated.')
    end
  end
end
