# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging }, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/345674', type: :bug } do
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
        Runtime::Feature.enable(:top_level_group_creation_enabled)
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

      after do |example|
        user.remove_via_api!
        group.remove_via_api! unless example.exception

        Runtime::Feature.disable(:top_level_group_creation_enabled)
      end

      it 'adds additional minutes to group namespace', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2260' do
        Page::Group::Menu.perform(&:go_to_usage_quotas)
        Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
          usage_quota.pipeline_tab
          usage_quota.buy_ci_minutes
        end

        Gitlab::Page::Subscriptions::New.perform do |ci_minutes|
          ci_minutes.quantity = purchase_quantity
          ci_minutes.continue_to_billing

          ci_minutes.country = user_billing_info[:country]
          ci_minutes.street_address_1 = user_billing_info[:address_1]
          ci_minutes.street_address_2 = user_billing_info[:address_2]
          ci_minutes.city = user_billing_info[:city]
          ci_minutes.state = user_billing_info[:state]
          ci_minutes.zip_code = user_billing_info[:zip]
          ci_minutes.continue_to_payment

          ci_minutes.name_on_card = credit_card_info[:name]
          ci_minutes.card_number = credit_card_info[:number]
          ci_minutes.expiration_month = credit_card_info[:month]
          ci_minutes.expiration_year = credit_card_info[:year]
          ci_minutes.cvv = credit_card_info[:cvv]
          ci_minutes.review_your_order

          ci_minutes.confirm_purchase
        end

        Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
          expected_minutes = ci_product[:minutes] * purchase_quantity

          expect { usage_quota.purchase_successful_alert? }.to eventually_be_truthy.within(max_duration: 120, max_attempts: 60)
          expect { usage_quota.additional_minutes? }.to eventually_be_truthy.within(max_duration: 120, max_attempts: 60, reload_page: page)
          expect(usage_quota.additional_limits).to eq(expected_minutes.to_s)
        end
      end

      private

      # Hash presentation of CI minutes addon
      # @return [Hash] CI Minutes addon
      def ci_product
        {
          name: 'CI Minutes', # the name as it appears to purchase in GitLab
          price: 10, # unit price in USD
          minutes: 1000 # additional CI minutes per pack
        }.freeze
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
