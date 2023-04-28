# frozen_string_literal: true

module QA
  include QA::Support::Helpers::Plan

  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging }, product_group: :utilization do
    describe 'Utilization' do
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:start_date) { Time.now.utc.strftime("%B %-d, %Y") }
      let(:end_date) { Time.now.utc.advance(years: 1).strftime("%B %-d, %Y") }
      let(:hash) { SecureRandom.hex(8) }

      let(:user) do
        Resource::User.fabricate_via_api! do |user|
          user.email = "test-user-#{hash}@gitlab.com"
          user.api_client = admin_api_client
          user.hard_delete_on_api_removal = true
        end
      end

      let(:guest_user) do
        Resource::User.fabricate_via_api! do |user|
          user.api_client = admin_api_client
        end
      end

      let(:developer_user) do
        Resource::User.fabricate_via_api! do |user|
          user.api_client = admin_api_client
        end
      end

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
        group.add_member(guest_user, Resource::Members::AccessLevel::GUEST)
        group.add_member(developer_user, Resource::Members::AccessLevel::DEVELOPER)
        Page::Group::Menu.perform(&:go_to_billing)
      end

      after do
        user.remove_via_api!
        guest_user.remove_via_api!
        developer_user.remove_via_api!
      end

      context 'in ultimate plan billing settings' do
        it(
          'displays correct information for seat usage',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/373506'
        ) do
          Gitlab::Page::Group::Settings::Billing.perform do |billing|
            billing.wait_for_subscription('ultimate saas', page: page)
            billing.refresh_subscription_seats

            aggregate_failures do
              expect { billing.seats_in_subscription }.to eventually_eq('1')
              # Members with Guest permissions on an Ultimate subscription do not count towards the subscription
              expect { billing.seats_currently_in_use }.to eventually_eq('2')
              expect { billing.max_seats_used }.to eventually_eq('2')
              expect { billing.seats_owed }.to eventually_eq('1')

              expect(billing.subscription_start_date).to eq(start_date)
              expect(billing.subscription_end_date).to eq(end_date)

              expect(billing.subscription_header).to match(/#{group.path}: Ultimate SaaS Plan/i)
              expect(billing.billing_plan_header)
                .to match(/#{group.path} is currently using the Ultimate SaaS Plan/i)
            end
          end
        end
      end
    end
  end
end
