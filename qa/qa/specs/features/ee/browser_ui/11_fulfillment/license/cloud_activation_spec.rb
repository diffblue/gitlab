# frozen_string_literal: true

module QA
  include QA::Support::Helpers::Plan

  RSpec.describe 'Fulfillment', :requires_admin, :orchestrated, :cloud_activation do
    let(:user) { 'GitLab QA' }
    let(:company) { 'QA User' }
    let(:user_count) { 10_000 }
    let(:plan) { ULTIMATE_SELF_MANAGED }

    before do
      Flow::Login.sign_in_as_admin
      Gitlab::Page::Admin::Subscription.perform do |subscription|
        subscription.visit
        # workaround for UI bug https://gitlab.com/gitlab-org/gitlab/-/issues/365305
        expect { subscription.no_active_subscription_title? }.to eventually_be_truthy.within(max_attempts: 60, reload_page: page)
      end
    end

    after do
      remove_license if Gitlab::Page::Admin::Subscription.perform(&:subscription_details?)
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

      it 'shows correct billable user on subscription page', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/364830' do
        Gitlab::Page::Admin::Subscription.perform do |subscription|
          # `root` admin user also shows as billable user by default
          expect(subscription.billable_users.to_i).to eq(billable_user_count + 1)
        end
      end
    end

    context 'Remove cloud subscription' do
      before do
        activate_license
      end

      it 'successfully removes a cloud activation and shows flash notice', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/364831' do
        remove_license

        Gitlab::Page::Admin::Subscription.perform do |subscription|
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

    def remove_license
      Gitlab::Page::Admin::Subscription.perform do |subscription|
        subscription.remove_license
        subscription.confirm_ok_button

        expect { subscription.no_valid_license_alert? }.to eventually_be_truthy.within(max_duration: 60, max_attempts: 30)
      end
    end
  end
end
