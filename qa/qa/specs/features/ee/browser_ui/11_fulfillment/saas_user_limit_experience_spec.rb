# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :requires_admin,
                 only: { subdomain: :staging },
                 product_group: :billing_and_subscription_management,
                 feature_flag: { name: 'free_user_cap', scope: :group } do
    describe 'Utilization' do
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:owner_api_client) { Runtime::API::Client.new(:gitlab, user: group_owner) }
      let(:hash) { SecureRandom.hex(8) }

      let(:group_owner) do
        Resource::User.fabricate_via_api! do |user|
          user.email = "test-user-#{hash}@gitlab.com"
          user.api_client = admin_api_client
          user.hard_delete_on_api_removal = true
        end
      end

      let(:user_2) { Resource::User.fabricate_via_api! { |user| user.api_client = admin_api_client } }
      let(:user_3) { Resource::User.fabricate_via_api! { |user| user.api_client = admin_api_client } }
      let(:user_4) { Resource::User.fabricate_via_api! { |user| user.api_client = admin_api_client } }
      let(:user_5) { Resource::User.fabricate_via_api! { |user| user.api_client = admin_api_client } }
      let(:user_6) { Resource::User.fabricate_via_api! { |user| user.api_client = admin_api_client } }
      let(:user_7) { Resource::User.fabricate_via_api! { |user| user.api_client = admin_api_client } }

      let(:private_group) do
        Resource::Sandbox.fabricate! do |sandbox|
          sandbox.path = "fulfillment-private-group-#{hash}"
          sandbox.api_client = owner_api_client
          sandbox.visibility = 'private'
        end
      end

      let(:invitee_group) do
        Resource::Sandbox.fabricate! do |sandbox|
          sandbox.path = "invitee-group-#{hash}"
          sandbox.api_client = owner_api_client
          sandbox.visibility = 'private'
        end
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.api_client = owner_api_client
          project.name = "test-project-#{hash}"
          project.group = private_group
        end
      end

      before do
        Flow::Login.sign_in(as: group_owner)
      end

      after do
        Runtime::Feature.disable(:preview_free_user_cap, group: private_group)
        Runtime::Feature.disable(:notification_free_user_cap_show_over_limit, group: private_group)
        Runtime::Feature.disable(:free_user_cap, group: private_group)
        Runtime::Feature.disable(:free_user_cap_new_namespaces, group: private_group)

        remove_resources(group_owner, user_2, user_3, user_4, user_5, user_6, user_7)
      end

      context 'when Saas user limit experience feature flags are enabled' do
        it(
          'preview notification displayed for private group when over limit',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387825'
        ) do
          create_private_group_with_members
          Runtime::Feature.enable(:preview_free_user_cap, group: private_group)
          Runtime::Feature.enable(:notification_free_user_cap_show_over_limit, group: private_group)
          private_group.add_member(user_6)
          page.refresh

          expect { page }
            .to eventually_have_content(notifications(private_group, :limit_overage_preview_msg))
                  .within(max_attempts: 5, sleep_interval: 2, reload_page: page)
        end

        it(
          'limit overage enforcement removed from private group when trial is started',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387826'
        ) do
          # Check enforcement notification for limit overage
          create_private_group_with_members
          private_group.add_member(user_6)
          Runtime::Feature.enable(:free_user_cap, group: private_group)
          Runtime::Feature.enable(:free_user_cap_new_namespaces, group: private_group)
          page.refresh

          expect { page }
            .to eventually_have_content(notifications(private_group, :limit_overage_enforcement_msg))
                  .within(max_attempts: 5, sleep_interval: 2, reload_page: page)

          # Remove the enforcement by starting a free Ultimate Trial
          Page::Trials::New.perform(&:visit)
          Flow::Trial.register_for_trial(skip_select: true)
          private_group.add_member(user_7)
          private_group.visit!

          aggregate_failures do
            expect(page).not_to have_content(notifications(private_group, :limit_overage_enforcement_msg))
            expect { private_group.list_members.count }.to eventually_eq(7)
          end
        end

        it(
          'new group enforcement removed when trial started',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387827'
        ) do
          Runtime::Feature.enable(:free_user_cap, group: private_group)
          Runtime::Feature.enable(:free_user_cap_new_namespaces, group: private_group)
          create_private_group_with_members
          page.refresh

          expect { page }
            .to eventually_have_content(notifications(private_group, :limit_reached_enforcement_msg))
                  .within(max_attempts: 5, sleep_interval: 2, reload_page: page)

          Page::Trials::New.perform(&:visit)
          Flow::Trial.register_for_trial(skip_select: true)
          private_group.visit!

          expect(page).not_to have_content(notifications(private_group, :limit_reached_enforcement_msg))
        end

        it(
          'enforcement does not allow adding more members',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387828'
        ) do
          create_private_group_with_members
          Runtime::Feature.enable(:free_user_cap, group: private_group)
          Runtime::Feature.enable(:free_user_cap_new_namespaces, group: private_group)

          # Checks that it fails to add an additional member due to enforcement
          begin
            private_group.add_member(user_6)
          rescue Support::Repeater::RetriesExceededError
            expect { private_group.list_members.count }.to eventually_eq(5)
          end
        end

        it(
          'enforcement limit counts includes invited group and project members',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387829'
        ) do
          Runtime::Feature.enable(:free_user_cap, group: private_group)
          Runtime::Feature.enable(:free_user_cap_new_namespaces, group: private_group)

          add_members(project, user_2)
          add_members(private_group, user_3)
          add_members(invitee_group, user_4, user_5, user_6)

          private_group.invite_group(invitee_group)
          private_group.visit!

          aggregate_failures do
            expect { page }
              .to eventually_have_content(notifications(private_group, :limit_overage_enforcement_msg))
                    .within(max_attempts: 5, sleep_interval: 2, reload_page: page)
            expect(private_group.list_all_members.count).to eq(5) # excludes project unique members
            expect(invitee_group.list_members.count).to eq(4)
          end
        end
      end

      private

      # Adds members to group or project
      #
      # @param [Resource::Group|Resource::Project] group_or_project
      # @param [Array<Resource::User] members
      def add_members(group_or_project, *members)
        members.each do |member|
          group_or_project.add_member(member)
        end
      end

      # group_owner is also counted, free user member limit for private group is 5
      def create_private_group_with_members
        add_members(private_group, user_2, user_3, user_4, user_5)
      end

      # Clean up resources
      #
      # @param [Array<Resource>] resources
      def remove_resources(*resources)
        resources.each(&:remove_via_api!)
      end

      # Returns user limit notification message
      #
      # @param [Resource::Group] group
      # @param [Symbol] type notification message type
      def notifications(group, type)
        {
          limit_overage_preview_msg:
            "Your top-level group #{group.path} is over the 5 user limit GitLab will enforce this limit in the future",
          limit_reached_enforcement_msg:
            "Your top-level group #{group.path} has reached the 5 user limit To invite more users,
            you can reduce the number of users in your top-level group to 5 users or less",
          limit_overage_enforcement_msg:
            "Your top-level group #{group.path} is over the 5 user limit and has been placed in a read-only state"
        }.fetch(type).squish
      end
    end
  end
end
