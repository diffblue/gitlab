# frozen_string_literal: true

module QA
  include QA::Support::Helpers::Plan

  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging } do
    context 'Purchase CI minutes' do
      # the quantity of products to purchase
      let(:purchase_quantity) { 5 }
      let(:hash) { SecureRandom.hex(4) }
      let(:user) do
        Resource::User.fabricate_via_api! do |user|
          user.email = "test-user-#{hash}@gitlab.com"
          user.api_client = Runtime::API::Client.as_admin
          user.hard_delete_on_api_removal = true
        end
      end

      let(:group) do
        Resource::Sandbox.fabricate! do |sandbox|
          sandbox.path = "gitlab-qa-group-#{hash}"
          sandbox.api_client = Runtime::API::Client.as_admin
        end
      end

      before do
        group.add_member(user, Resource::Members::AccessLevel::OWNER)

        # A group project is required for additional CI Minutes to show up
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'ci-minutes'
          project.group = group
          project.initialize_with_readme = true
          project.api_client = Runtime::API::Client.as_admin
        end

        Flow::Login.sign_in(as: user)
        group.visit!
      end

      after do
        user.remove_via_api!
      end

      context 'without active subscription' do
        after do
          group.remove_via_api!
        end

        it 'adds additional minutes to group namespace', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2260' do
          purchase_ci_minutes

          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            expected_minutes = CI_MINUTES[:ci_minutes] * purchase_quantity

            expect { usage_quota.ci_purchase_successful_alert? }.to eventually_be_truthy.within(max_duration: 60, max_attempts: 30)
            expect { usage_quota.additional_ci_minutes? }.to eventually_be_truthy.within(max_duration: 120, max_attempts: 60, reload_page: page)
            expect(usage_quota.additional_ci_limits).to eq(expected_minutes.to_s)
          end
        end
      end

      context 'with an active subscription' do
        before do
          Page::Group::Menu.perform(&:go_to_billing)
          Gitlab::Page::Group::Settings::Billing.perform(&:upgrade_to_ultimate)

          Gitlab::Page::Subscriptions::New.perform do |new_subscription|
            new_subscription.continue_to_billing

            fill_in_customer_info
            fill_in_payment_info

            new_subscription.confirm_purchase
          end
        end

        it 'adds additional minutes to group namespace', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2430' do
          purchase_ci_minutes

          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            expected_minutes = CI_MINUTES[:ci_minutes] * purchase_quantity
            plan_limits = ULTIMATE[:ci_minutes]

            expect { usage_quota.ci_purchase_successful_alert? }.to eventually_be_truthy.within(max_duration: 60, max_attempts: 30)
            expect { usage_quota.additional_ci_minutes? }.to eventually_be_truthy.within(max_duration: 120, max_attempts: 60, reload_page: page)
            aggregate_failures do
              expect(usage_quota.additional_ci_limits).to eq(expected_minutes.to_s)
              expect(usage_quota.plan_ci_limits).to eq(plan_limits.to_s)
            end
          end
        end
      end

      context 'with existing CI minutes packs' do
        before do
          purchase_ci_minutes
        end

        after do
          group.remove_via_api!
        end

        it 'adds additional minutes to group namespace', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2431' do
          purchase_ci_minutes

          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            expected_minutes = CI_MINUTES[:ci_minutes] * purchase_quantity * 2

            expect { usage_quota.ci_purchase_successful_alert? }.to eventually_be_truthy.within(max_duration: 60, max_attempts: 30)
            expect { usage_quota.additional_ci_minutes? }.to eventually_be_truthy.within(max_duration: 120, max_attempts: 60, reload_page: page)
            expect { usage_quota.additional_ci_limits }.to eventually_eq(expected_minutes.to_s).within(max_duration: 120, max_attempts: 60, reload_page: page)
          end
        end
      end

      private

      def purchase_ci_minutes
        Page::Group::Menu.perform(&:go_to_usage_quotas)
        Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
          usage_quota.pipeline_tab
          usage_quota.buy_ci_minutes
        end

        Gitlab::Page::Subscriptions::New.perform do |ci_minutes|
          ci_minutes.quantity = purchase_quantity
          ci_minutes.continue_to_billing

          fill_in_customer_info
          fill_in_payment_info

          ci_minutes.confirm_purchase
        end
      end

      def fill_in_customer_info
        Gitlab::Page::Subscriptions::New.perform do |subscription|
          subscription.country = user_billing_info[:country]
          subscription.street_address_1 = user_billing_info[:address_1]
          subscription.street_address_2 = user_billing_info[:address_2]
          subscription.city = user_billing_info[:city]
          subscription.state = user_billing_info[:state]
          subscription.zip_code = user_billing_info[:zip]
          subscription.continue_to_payment
        end
      end

      def fill_in_payment_info
        Gitlab::Page::Subscriptions::New.perform do |subscription|
          subscription.name_on_card = credit_card_info[:name]
          subscription.card_number = credit_card_info[:number]
          subscription.expiration_month = credit_card_info[:month]
          subscription.expiration_year = credit_card_info[:year]
          subscription.cvv = credit_card_info[:cvv]
          subscription.review_your_order
        end
      end

      def credit_card_info
        {
          name: 'QA Test',
          number: '4111111111111111',
          month: '01',
          year: '2025',
          cvv: '232'
        }.freeze
      end

      def user_billing_info
        {
          country: 'United States of America',
          address_1: 'Address 1',
          address_2: 'Address 2',
          city: 'San Francisco',
          state: 'California',
          zip: '94102'
        }.freeze
      end
    end
  end
end
