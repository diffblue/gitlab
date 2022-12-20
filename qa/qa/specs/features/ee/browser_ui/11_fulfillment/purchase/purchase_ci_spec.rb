# frozen_string_literal: true

module QA
  include QA::Support::Helpers::Plan

  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging }, product_group: :purchase do
    describe 'Purchase CI minutes' do
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
          sandbox.path = "test-group-fulfillment#{hash}"
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

          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            expected_minutes = CI_MINUTES[:ci_minutes] * purchase_quantity

            expect { usage_quota.ci_purchase_successful_alert? }
              .to eventually_be_truthy.within(max_duration: 60, max_attempts: 30)
            expect { usage_quota.additional_ci_minutes_added? }
              .to eventually_be_truthy.within(max_duration: 120, max_attempts: 60, reload_page: page)
            expect(usage_quota.additional_ci_limits).to eq(expected_minutes.to_s)
          end
        end
      end

      context 'with an active subscription' do
        before do
          Flow::Purchase.upgrade_subscription(plan: ULTIMATE)
        end

        it 'adds additional minutes to group namespace',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347569' do
          Flow::Purchase.purchase_ci_minutes(quantity: purchase_quantity)

          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            expected_minutes = CI_MINUTES[:ci_minutes] * purchase_quantity
            plan_limits = ULTIMATE[:ci_minutes]

            expect { usage_quota.ci_purchase_successful_alert? }
              .to eventually_be_truthy.within(max_duration: 60, max_attempts: 30)
            expect { usage_quota.additional_ci_minutes_added? }
              .to eventually_be_truthy.within(max_duration: 120, max_attempts: 60, reload_page: page)
            aggregate_failures do
              expect(usage_quota.additional_ci_limits).to eq(expected_minutes.to_s)
              expect(usage_quota.plan_ci_limits).to eq(plan_limits.to_s)
            end
          end
        end
      end

      context 'with existing CI minutes packs' do
        before do
          Flow::Purchase.purchase_ci_minutes(quantity: purchase_quantity)
        end

        after do
          group.remove_via_api!
        end

        it 'adds additional minutes to group namespace',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347568' do
          Flow::Purchase.purchase_ci_minutes(quantity: purchase_quantity)

          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            expected_minutes = CI_MINUTES[:ci_minutes] * purchase_quantity * 2

            expect { usage_quota.ci_purchase_successful_alert? }
              .to eventually_be_truthy.within(max_duration: 60, max_attempts: 30)
            expect { usage_quota.additional_ci_minutes_added? }
              .to eventually_be_truthy.within(max_duration: 120, max_attempts: 60, reload_page: page)
            expect { usage_quota.additional_ci_limits }
              .to eventually_eq(expected_minutes.to_s).within(max_duration: 120, max_attempts: 60, reload_page: page)
          end
        end
      end
    end
  end
end
