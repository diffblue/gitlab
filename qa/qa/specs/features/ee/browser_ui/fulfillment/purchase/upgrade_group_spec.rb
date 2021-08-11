# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging } do
    describe 'Purchase' do
      describe 'group plan' do
        let(:hash) { SecureRandom.hex(4) }
        let(:user) do
          Resource::User.fabricate_via_api! do |user|
            user.email = "gitlab-qa+#{hash}@gitlab.com"
            user.api_client = Runtime::API::Client.as_admin
            user.hard_delete_on_api_removal = true
          end
        end

        # Normally we would delete the group, however we cannot remove this group
        # after the test runs since GitLab will not allow deletion of a group
        # that has a Subscription attached
        let(:group) do
          Resource::Sandbox.fabricate_via_api! do |sandbox|
            sandbox.path = "gitlab-qa-group-#{hash}"
            sandbox.api_client = Runtime::API::Client.as_admin
          end
        end

        before do
          Runtime::Feature.enable(:top_level_group_creation_enabled)

          group.add_member(user, Resource::Members::AccessLevel::OWNER)
          Flow::Login.sign_in(as: user)

          group.visit!
        end

        after do
          user.remove_via_api!

          Runtime::Feature.disable(:top_level_group_creation_enabled)
        end

        it 'upgrades from free to ultimate', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1863' do
          Page::Group::Menu.perform(&:go_to_billing)
          Gitlab::Page::Group::Settings::Billing.perform(&:upgrade_to_ultimate)

          Gitlab::Page::Subscriptions::New.perform do |new_subscription|
            # Subscription details
            new_subscription.continue_to_billing

            # Billing information
            new_subscription.country = 'United States of America'
            new_subscription.street_address_1 = 'QA Test Address 1'
            new_subscription.city = 'San Francisco'
            new_subscription.state = 'California'
            new_subscription.zip_code = '94102'
            new_subscription.continue_to_payment

            # Payment method
            new_subscription.name_on_card = 'QA Test User'
            new_subscription.card_number = '4111 1111 1111 1111'
            new_subscription.expiration_month = '01'
            new_subscription.expiration_year = '2030'
            new_subscription.cvv = '789'
            new_subscription.review_your_order

            # Confirm
            new_subscription.confirm_purchase
          end

          Page::Group::Menu.perform(&:go_to_billing)

          Gitlab::Page::Group::Settings::Billing.perform do |billing|
            expect do
              billing.billing_plan_header
            end.to eventually_include("#{group.name} is currently using the Ultimate SaaS Plan").within(max_duration: 120, max_attempts: 60, reload_page: page)
          end
        end
      end
    end
  end
end
