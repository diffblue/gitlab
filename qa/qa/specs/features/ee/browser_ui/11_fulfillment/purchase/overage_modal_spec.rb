# frozen_string_literal: true

module QA
  include QA::Support::Helpers::Plan

  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging },
                 product_group: :billing_and_subscription_management do
    describe 'Seat overage modal' do
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:hash) { SecureRandom.hex(8) }

      let(:group_owner) do
        Resource::User.fabricate_via_api! do |user|
          user.email = "test-user-#{hash}@gitlab.com"
          user.api_client = admin_api_client
          user.hard_delete_on_api_removal = true
        end
      end

      let(:developer_user) do
        Resource::User.fabricate_via_api! { |user| user.api_client = admin_api_client }
      end

      let(:user1) do
        Resource::User.fabricate_via_api! { |user| user.api_client = admin_api_client }
      end

      # This group can't be removed while it is linked to a subscription.
      let(:group) do
        Resource::Sandbox.fabricate! do |sandbox|
          sandbox.path = "fulfillment-overage-test-group-#{hash}"
          sandbox.api_client = admin_api_client
        end
      end

      let(:member_group) do
        Resource::Sandbox.fabricate! do |member_group|
          member_group.path = "fulfillment-overage-member-group-#{hash}"
          member_group.api_client = admin_api_client
        end
      end

      let(:overage_string) { "You are about to incur additional charges" }

      let(:overage_regex_string) do
        /If you continue, the #{group.path} group will have \d seats in use and will be billed for the overage/
      end

      shared_examples 'overage for member invite' do |role|
        it 'shows the modal' do
          invite_member(user1.username, role)

          check_if_overage_modal_present
          Page::Group::Members.perform(&:send_invite)

          expect(find_member_in_group(user1)).to be_truthy
        end
      end

      shared_examples 'overage for group invite' do |role|
        it 'shows the modal' do
          member_group.add_member(group_owner, Resource::Members::AccessLevel::DEVELOPER)
          member_group.add_member(user1, Resource::Members::AccessLevel::DEVELOPER)
          invite_group(member_group.path, role)

          check_if_overage_modal_present
          Page::Group::Members.perform(&:send_invite)

          expect(find_shared_group(member_group)).to be_truthy
        end
      end

      before do
        Flow::Login.sign_in(as: group_owner)
        group.visit!
      end

      after do
        group_owner&.remove_via_api!
        user1&.remove_via_api!
        developer_user&.remove_via_api!
      end

      context 'with ultimate plan' do
        before do
          Flow::Purchase.upgrade_subscription(plan: ULTIMATE)
          wait_until_subscripton_upgraded?
          group.add_member(developer_user, Resource::Members::AccessLevel::DEVELOPER)
          group.visit!
        end

        context 'for member invite' do
          context(
            'when access level developer or above is added',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387615'
          ) do
            it_behaves_like 'overage for member invite', 'Developer'
          end

          it 'does not show overage modal when inviting a member as a guest',
             testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387616' do
            invite_member(user1.username, 'Guest')

            check_if_overage_modal_absent

            expect(find_member_in_group(user1)).to be_truthy
          end
        end

        context 'for group invite' do
          it 'does not show overage modal when inviting a group which does not increase seats owed',
             testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387614' do
            member_group.add_member(group_owner, Resource::Members::AccessLevel::DEVELOPER)
            invite_group(member_group.path, 'Developer')

            check_if_overage_modal_absent
            expect(find_shared_group(member_group)).to be_truthy
          end

          context 'when inviting a group with developer role which increases seats owed',
             testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387613' do
            it_behaves_like 'overage for group invite', 'Developer'
          end
        end
      end

      context 'with premium plan' do
        before do
          Flow::Purchase.upgrade_subscription(plan: PREMIUM)
          wait_until_subscripton_upgraded?(plan: "Premium")
          group.add_member(developer_user, Resource::Members::AccessLevel::DEVELOPER)
          group.visit!
        end

        context 'for member invite' do
          context 'when guest role is added',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/388303' do
            it_behaves_like 'overage for member invite', 'Guest'
          end
        end

        context 'for group invite' do
          context 'when inviting a group with Guest role which increases seats owed',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/388306' do
            it_behaves_like 'overage for group invite', 'Guest'
          end
        end
      end

      def wait_until_subscripton_upgraded?(plan: "Ultimate")
        Gitlab::Page::Group::Settings::Billing.perform do |billing|
          expect do
            billing.billing_plan_header
          end.to eventually_include("#{group.path} is currently using the #{plan} SaaS Plan")
                   .within(max_duration: 120, max_attempts: 30, sleep_interval: 2, reload_page: page)
        end
      end

      def invite_member(user_name, access_level)
        Page::Group::Menu.perform(&:click_group_members_item)
        Page::Group::Members.perform do |members_page|
          members_page.add_member(user_name, access_level, refresh_page: false)
        end
      end

      def invite_group(group_path, access_level)
        group.visit! # Note that this is the parent group
        Page::Group::Menu.perform(&:click_group_members_item)
        Page::Group::Members.perform do |members_page|
          members_page.invite_group(group_path, access_level, refresh_page: false)
        end
      end

      def check_if_overage_modal_present
        expect(page).to have_content(overage_string)
        expect(page).to have_content(overage_regex_string)
      end

      def check_if_overage_modal_absent
        expect(page).not_to have_content(overage_string)
      end

      def find_member_in_group(user)
        group.reload!.list_members.find { |usr| usr[:username] == user.username }
      end

      def find_shared_group(member_group)
        group.reload!.shared_with_groups.find { |grp| grp[:group_name] == member_group.name }
      end
    end
  end
end
