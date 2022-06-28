# frozen_string_literal: true

module QA
  include QA::Support::Helpers::Plan

  RSpec.describe 'Fulfillment', :requires_admin, :orchestrated, :cloud_activation do
    let(:user) { 'GitLab QA' }
    let(:company) { 'QA User' }
    let(:user_count) { 10_000 }
    let(:plan) { ULTIMATE_SELF_MANAGED }

    before do
      # Ensure the Gitlab instance does not already have an active license
      EE::Resource::License.delete_all

      Flow::Login.sign_in_as_admin
      Gitlab::Page::Admin::Subscription.perform do |subscription|
        subscription.visit
        # workaround for UI bug https://gitlab.com/gitlab-org/gitlab/-/issues/365305
        expect { subscription.no_active_subscription_title? }.to eventually_be_truthy.within(max_attempts: 60, reload_page: page)
      end
    end

    after do
      EE::Resource::License.delete_all
    end

    context 'Cloud activation code' do
      it 'activates instance with correct subscription details', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/350294' do
        activate_license

        Gitlab::Page::Admin::Subscription.perform do |subscription|
          aggregate_failures do
            expect { subscription.subscription_details?}.to eventually_be_truthy.within(max_duration: 60)
            expect(subscription.name).to eq(user)
            expect(subscription.company).to include(company)
            expect(subscription.plan).to eq(plan[:name].capitalize)
            expect(subscription.users_in_subscription).to eq(user_count.to_s)
            expect(subscription).to have_subscription_record(plan, user_count, LICENSE_TYPE[:online_cloud])
          end
        end
      end
    end

    context 'License usage' do
      before do
        activate_license
      end

      it 'shows correct billable user on subscription page',
         testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/364830',
         quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/366093', type: :flaky } do
        Gitlab::Page::Admin::Subscription.perform do |subscription|
          expect(subscription.billable_users.to_i).to eq(billable_user_count)
        end
      end
    end

    context 'Remove cloud subscription' do
      before do
        activate_license
      end

      it 'successfully removes a cloud activation and shows flash notice', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/364831' do
        Gitlab::Page::Admin::Subscription.perform do |subscription|
          subscription.remove_license
          subscription.confirm_ok_button

          expect { subscription.no_valid_license_alert? }.to eventually_be_truthy.within(max_duration: 60, max_attempts: 30)
          expect { subscription.no_active_subscription_title? }.to eventually_be_truthy.within(max_duration: 60, max_attempts: 30, reload_page: page)
        end
      end
    end

    private

    def billable_user_count
      Resource::User.all.select { _1[:using_license_seat] == true }.size
    end

    def activate_license
      Gitlab::Page::Admin::Subscription.perform do |subscription|
        subscription.activation_code = Runtime::Env.ee_activation_code
        subscription.accept_terms
        subscription.activate
      end
    end
  end
end
