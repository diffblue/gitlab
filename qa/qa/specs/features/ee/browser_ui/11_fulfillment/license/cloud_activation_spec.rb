# frozen_string_literal: true

module QA
  include QA::Support::Helpers::Plan

  RSpec.describe 'Fulfillment', :requires_admin, :orchestrated, :cloud_activation do
    let(:user) { 'GitLab QA' }
    let(:company) { 'QA User' }
    let(:user_count) { 10_000 }
    let(:plan) { ULTIMATE_SELF_MANAGED }

    context 'Cloud activation code' do
      before do
        Flow::Login.sign_in_as_admin
        Gitlab::Page::Admin::Subscription.perform(&:visit)
      end

      it 'activates instance with correct subscription details', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/350294' do
        Gitlab::Page::Admin::Subscription.perform do |subscription|
          subscription.activation_code = Runtime::Env.ee_activation_code
          subscription.accept_terms
          subscription.activate

          aggregate_failures do
            expect { subscription.subscription_details?}.to eventually_be_truthy.within(max_duration: 60)
            expect(subscription.name).to eq(user)
            expect(subscription.company).to include(company)
            expect(subscription.plan).to eq(plan[:name].capitalize)
            expect(subscription.users_in_subscription).to eq(user_count.to_s)
            expect(subscription).to have_subscription_record(plan, user_count, LICENSE_TYPE[:cloud_license])
          end
        end
      end
    end
  end
end
