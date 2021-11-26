# frozen_string_literal: true

module QA
  include QA::Support::Helpers::Plan

  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging } do
    context 'Purchase Storage' do
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
        Runtime::Feature.enable(:new_route_storage_purchase)
        group.add_member(user, Resource::Members::AccessLevel::OWNER)

        Resource::Project.fabricate_via_api! do |project|
          project.name = 'storage'
          project.group = group
          project.initialize_with_readme = true
          project.api_client = Runtime::API::Client.as_admin
        end

        Flow::Login.sign_in(as: user)
        group.visit!
      end

      after do |example|
        Runtime::Feature.disable(:new_route_storage_purchase)
        user.remove_via_api!
        group.remove_via_api! unless example.exception
      end

      it 'adds additional storage to group namespace', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2424' do
        Page::Group::Menu.perform(&:go_to_usage_quotas)
        Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
          usage_quota.storage_tab
          usage_quota.buy_storage
        end

        Gitlab::Page::Subscriptions::New.perform do |storage|
          storage.quantity = purchase_quantity
          storage.continue_to_billing

          storage.country = user_billing_info[:country]
          storage.street_address_1 = user_billing_info[:address_1]
          storage.street_address_2 = user_billing_info[:address_2]
          storage.city = user_billing_info[:city]
          storage.state = user_billing_info[:state]
          storage.zip_code = user_billing_info[:zip]
          storage.continue_to_payment

          storage.name_on_card = credit_card_info[:name]
          storage.card_number = credit_card_info[:number]
          storage.expiration_month = credit_card_info[:month]
          storage.expiration_year = credit_card_info[:year]
          storage.cvv = credit_card_info[:cvv]
          storage.review_your_order

          storage.confirm_purchase
        end

        Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
          expected_storage = STORAGE[:storage] * purchase_quantity

          expect { usage_quota.storage_purchase_successful_alert? }.to eventually_be_truthy.within(max_duration: 60, max_attempts: 30)
          expect { usage_quota.purchased_storage_available? }.to eventually_be_truthy.within(max_duration: 120, max_attempts: 60, reload_page: page)
          expect { usage_quota.total_purchased_storage }.to eventually_eq(expected_storage.to_f).within(max_duration: 120, max_attempts: 60, reload_page: page)
        end
      end

      private

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
