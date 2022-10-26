# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging }, product_group: :purchase do
    let(:admin_api_client) { Runtime::API::Client.as_admin }
    let(:start_date) { Date.today.strftime("%B %-d, %Y") }
    let(:user) do
      Resource::User.fabricate_via_api! do |user|
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

    let(:free_plan_group) do
      Resource::Sandbox.fabricate! do |sandbox|
        sandbox.path = "fulfillment-free-plan-group-#{SecureRandom.hex(8)}"
        sandbox.api_client = admin_api_client
      end
    end

    before do
      Flow::Login.sign_in(as: user)
      free_plan_group.visit!
      free_plan_group.add_member(guest_user, Resource::Members::AccessLevel::GUEST)
      free_plan_group.add_member(developer_user, Resource::Members::AccessLevel::DEVELOPER)
      Page::Group::Menu.perform(&:go_to_billing)
    end

    after do
      user.remove_via_api!
      guest_user.remove_via_api!
      developer_user.remove_via_api!
    end

    context 'free tier group namespace' do
      it(
        'displays correct information in billing settings',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/361076',
        quarantine: {
          only: { subdomain: :staging },
          type: :test_environment,
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/364229'
        }
      ) do
        Gitlab::Page::Group::Settings::Billing.perform do |billing|
          billing.refresh_subscription_seats

          aggregate_failures do
            expect { billing.seats_in_subscription }.to eventually_eq("-")
            expect { billing.seats_currently_in_use }.to eventually_eq("3")
            expect { billing.max_seats_used }.to eventually_eq("3")
            expect { billing.seats_owed }.to eventually_eq("-")

            expect(billing.subscription_start_date).to eq(start_date)
            expect(billing.subscription_end_date).to eq("-")

            expect(billing.subscription_header).to include("#{free_plan_group.path}: Free")
            expect(billing.billing_plan_header)
              .to include("#{free_plan_group.path} is currently using the Free Plan")
          end
        end
      end
    end
  end
end
