# frozen_string_literal: true

module QA
  include QA::Support::Helpers::Plan

  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging }, product_group: :purchase do
    describe 'Purchase' do
      describe 'group plan' do
        let(:hash) { SecureRandom.hex(4) }
        let(:user) do
          Resource::User.fabricate_via_api! do |user|
            user.email = "test-user-#{hash}@gitlab.com"
            user.api_client = Runtime::API::Client.as_admin
            user.hard_delete_on_api_removal = true
          end
        end

        # Normally we would delete the group, however we cannot remove this group
        # after the test runs since GitLab will not allow deletion of a group
        # that has a Subscription attached
        let(:group) do
          Resource::Sandbox.fabricate! do |sandbox|
            sandbox.path = "test-group-fulfillment#{hash}"
            sandbox.api_client = Runtime::API::Client.as_admin
          end
        end

        before do
          Flow::Login.sign_in(as: user)

          group.visit!
        end

        after do
          user.remove_via_api!
        end

        it 'upgrades from free to ultimate',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347667' do
          Flow::Purchase.upgrade_subscription(plan: ULTIMATE)

          Page::Group::Menu.perform(&:go_to_billing)

          Gitlab::Page::Group::Settings::Billing.perform do |billing|
            expect do
              billing.billing_plan_header
            end.to eventually_include("#{group.path} is currently using the Ultimate SaaS Plan")
                     .within(max_duration: 120, max_attempts: 60, reload_page: page)
          end
        end

        context 'with existing CI minutes pack' do
          let(:ci_minutes_quantity) { 5 }

          before do
            Resource::Project.fabricate_via_api! do |project|
              project.name = 'ci-minutes'
              project.group = group
              project.initialize_with_readme = true
              project.api_client = Runtime::API::Client.as_admin
            end

            Flow::Purchase.purchase_ci_minutes(quantity: ci_minutes_quantity)
          end

          it 'upgrades from free to premium with correct CI minutes',
             testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349085' do
            Flow::Purchase.upgrade_subscription(plan: PREMIUM)

            expected_minutes = CI_MINUTES[:ci_minutes] * ci_minutes_quantity
            plan_limits = PREMIUM[:ci_minutes]

            Page::Group::Menu.perform(&:go_to_billing)
            Gitlab::Page::Group::Settings::Billing.perform do |billing|
              expect do
                billing.billing_plan_header
              end.to eventually_include("#{group.path} is currently using the Premium SaaS Plan")
                       .within(max_duration: 120, max_attempts: 60, sleep_interval: 2, reload_page: page)
            end

            Page::Group::Menu.perform(&:go_to_usage_quotas)
            Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
              usage_quota.pipelines_tab

              expect { usage_quota.additional_ci_minutes_added? }
                .to eventually_be_truthy.within(max_duration: 120, max_attempts: 60, reload_page: page)
              aggregate_failures do
                expect(usage_quota.additional_ci_limits).to eq(expected_minutes.to_s)
                expect(usage_quota.plan_ci_limits).to eq(plan_limits.to_s)
              end
            end
          end
        end
      end
    end
  end
end
