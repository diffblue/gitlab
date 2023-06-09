# frozen_string_literal: true

module QA
  include Support::Helpers::Plan
  include Support::Helpers::Zuora

  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging }, product_group: :purchase do
    describe 'Purchase CI minutes' do
      let(:purchase_quantity) { 5 }
      let(:expected_initial_minutes) { CI_MINUTES[:ci_minutes] * purchase_quantity }
      let(:hash) { SecureRandom.hex(4) }
      let(:user) do
        Resource::User.fabricate_via_api! do |user|
          user.email = "test-user-#{hash}@gitlab.com"
          user.api_client = Runtime::API::Client.as_admin
          user.hard_delete_on_api_removal = true
        end
      end

      # Group cannot be deleted until subscription is deleted in Zuora
      let(:group) do
        Resource::Sandbox.fabricate! do |sandbox|
          sandbox.path = "test-group-fulfillment-#{hash}"
          sandbox.api_client = Runtime::API::Client.as_admin
        end
      end

      before do
        Flow::Login.sign_in(as: user)

        # A group project is required for additional CI Minutes to show up
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'ci-minutes'
          project.group = group
          project.initialize_with_readme = true
          project.api_client = Runtime::API::Client.as_admin
        end

        group.visit!
      end

      after do
        user.remove_via_api!
      end

      context 'without active subscription' do
        after do
          group.remove_via_api!
        end

        it 'adds additional minutes to group namespace',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347622' do
          Flow::Purchase.purchase_ci_minutes(quantity: purchase_quantity)

          expect_additional_ci_minutes(expected_initial_minutes.to_s)
        end
      end

      context 'with an active subscription' do
        before do
          Flow::Purchase.upgrade_subscription(plan: ULTIMATE)
        end

        it 'adds additional minutes to group namespace',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347569' do
          Gitlab::Page::Group::Settings::Billing.perform do |billing|
            billing.wait_for_subscription(ULTIMATE[:name])
          end

          Flow::Purchase.purchase_ci_minutes(quantity: purchase_quantity)

          expect_additional_ci_minutes(expected_initial_minutes.to_s)

          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            expect(usage_quota.plan_ci_limits).to eq(ULTIMATE[:ci_minutes].to_s)
          end
        end
      end

      context 'with existing CI minutes packs' do
        let(:expected_total_minutes) { expected_initial_minutes * 2 }

        before do
          Flow::Purchase.purchase_ci_minutes(quantity: purchase_quantity)
        end

        after do
          group.remove_via_api!
        end

        it 'adds additional minutes to group namespace',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347568' do
          expect_additional_ci_minutes(expected_initial_minutes.to_s)

          Flow::Purchase.purchase_ci_minutes(quantity: purchase_quantity)

          expect_additional_ci_minutes(expected_total_minutes.to_s)
        end
      end
    end

    private

    def expect_additional_ci_minutes(expected_minutes)
      Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
        expect { usage_quota.ci_purchase_successful_alert? }
          .to eventually_be_truthy.within(max_duration: ZUORA_TIMEOUT)

        usage_quota.wait_for_additional_ci_minutes_available
        usage_quota.wait_for_additional_ci_minute_limits(expected_minutes)
      end
    end
  end
end
