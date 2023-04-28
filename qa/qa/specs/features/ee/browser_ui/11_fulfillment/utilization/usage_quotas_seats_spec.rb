# frozen_string_literal: true

module QA
  include QA::Support::Helpers::Plan

  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging }, product_group: :utilization do
    describe 'Utilization' do
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:hash) { SecureRandom.hex(8) }

      let(:user) do
        Resource::User.fabricate_via_api! do |user|
          user.email = "test-user-#{hash}@gitlab.com"
          user.api_client = admin_api_client
          user.hard_delete_on_api_removal = true
        end
      end

      let(:developer_user) { Resource::User.fabricate_via_api! { |user| user.api_client = admin_api_client } }
      let(:guest_user) { Resource::User.fabricate_via_api! { |user| user.api_client = admin_api_client } }

      # This group can't be removed while it is linked to a subscription.
      let(:group) do
        Resource::Sandbox.fabricate! do |sandbox|
          sandbox.path = "fulfillment-free-plan-group-#{hash}"
          sandbox.api_client = admin_api_client
        end
      end

      before do
        Flow::Login.sign_in(as: user)
        group.visit!
        Flow::Purchase.upgrade_subscription(plan: ULTIMATE)
        Support::Waiter.wait_until(max_duration: 15) { page.text.include?('successfully purchased') }
        Gitlab::Page::Group::Settings::Billing.perform do |billing|
          billing.wait_for_subscription('ultimate saas', page: page)
          group.add_member(guest_user, Resource::Members::AccessLevel::GUEST)
          group.add_member(developer_user, Resource::Members::AccessLevel::DEVELOPER)
          billing.refresh_subscription_seats
        end
      end

      context 'in usage quotas' do
        it(
          'user seat data is displayed correctly',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/377358'
        ) do
          Page::Group::Menu.perform(&:go_to_usage_quotas)
          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            aggregate_failures do
              expect(usage_quota.seats_in_use).to match(%r{2 / 1})
              expect(usage_quota.seats_in_use).to match(%r{Seats in use / Seats in subscription}i)
              expect(usage_quota.seats_used).to match(/2 Max seats used/i)
              expect(usage_quota.seats_owed).to match(/1 Seats owed/i)
              expect(usage_quota.subscription_users).to match(/#{user.name}/)
              expect(usage_quota.subscription_users).to match(/#{developer_user.name}/)
              # Guest user not shown in Usage Quotas seats for Ultimate License
              expect(usage_quota.subscription_users).not_to match(/#{guest_user.name}/)
              expect(usage_quota.group_usage_message).to match(/fulfillment-free-plan-group-#{hash} group/)
            end
          end
        end

        it(
          'max seats used count does not change after members are removed',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/408486'
        ) do
          Gitlab::Page::Group::Settings::Billing.perform do |billing|
            group.remove_member(developer_user)
            group.remove_member(guest_user)
            billing.refresh_subscription_seats
          end

          Page::Group::Menu.perform(&:go_to_usage_quotas)
          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            aggregate_failures do
              expect(usage_quota.seats_in_use).to match(%r{1 / 1})
              expect(usage_quota.seats_used).to match(%r{2 Max seats used}i)
              expect(usage_quota.seats_owed).to match(%r{1 Seats owed}i)
            end
          end
        end
      end
    end
  end
end
