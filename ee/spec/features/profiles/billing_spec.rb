# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profiles > Billing', :js, feature_category: :purchase do
  include StubRequests
  include SubscriptionPortalHelpers

  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:user) { create(:user, namespace: namespace) }

  def formatted_date(date)
    date.strftime("%B %-d, %Y")
  end

  def subscription_table
    '.subscription-table'
  end

  before do
    allow(Gitlab).to receive(:com?).and_return(true)
    stub_signing_key
    stub_application_setting(check_namespace_plan: true)
    stub_subscription_management_data(namespace.id)

    sign_in(user)
  end

  context 'when CustomersDot is available' do
    let(:plan) { 'free' }

    before do
      stub_billing_plans(user.namespace.id, plan)
    end

    context 'with a free plan' do
      let!(:subscription) do
        create(:gitlab_subscription, namespace: user.namespace, hosted_plan: nil)
      end

      it 'hides add seats and renew buttons' do
        visit profile_billings_path

        expect(page).not_to have_link("Add seats")
        expect(page).not_to have_link("Renew")
      end

      it 'does not have search settings field' do
        visit profile_billings_path

        expect(page).not_to have_field(placeholder: SearchHelpers::INPUT_PLACEHOLDER)
      end

      context "without a group" do
        it 'displays help for moving groups' do
          visit profile_billings_path

          expect(page).to have_content "You don't have any groups."
        end
      end

      context "with a maintained or owned group" do
        it 'displays help for moving groups' do
          create(:group).add_owner user
          visit profile_billings_path

          expect(page).not_to have_content "You don't have any groups"
          expect(page).to have_content "You'll have to move this project"
        end
      end
    end
  end
end
