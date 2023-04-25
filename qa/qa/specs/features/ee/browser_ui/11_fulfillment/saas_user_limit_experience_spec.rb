# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging },
    product_group: :billing_and_subscription_management do
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
        remove_resources(group_owner, user_2, user_3, user_4, user_5, user_6, user_7)
      end

      context 'when Saas user limit experience ' do
        context 'when group is in notification' do
          before do
            # Since we have logic for 'reached' the limit, we need to go over the notification_limit by going to 4
            # and still be under the dashboard_limit of 5 to see the notification message.
            # We also want to keep a matching scenario of production in staging, we don't want to have this
            # setting be permanent.
            Runtime::ApplicationSettings.set_application_settings(dashboard_notification_limit: 3)
          end

          after do
            Runtime::ApplicationSettings.restore_application_settings(:dashboard_notification_limit)
          end

          it(
            'preview notification displayed for private group when over limit',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387825'
          ) do
            private_group.add_members(user_2, user_3, user_4)
            page.refresh

            expect { page.text.squish }
              .to eventually_include(notifications(private_group, :limit_overage_preview_msg))
                    .within(max_attempts: 5, sleep_interval: 2, reload_page: page)
          end
        end

        it(
          'limit overage enforcement removed from private group when trial is started',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387826'
        ) do
          # Check enforcement notification for limit overage
          create_private_group_with_members
          send_private_group_over_limit
          private_group.visit!

          expect { page }
            .to eventually_have_content(notifications(private_group, :limit_overage_enforcement_msg))
                  .within(max_attempts: 5, sleep_interval: 2, reload_page: page)

          # Remove the enforcement by starting a free Ultimate Trial
          Gitlab::Page::Trials::New.perform(&:visit)
          # due to invited group used here we have more than one group so we have to select
          Flow::Trial.register_for_trial(group: private_group)
          private_group.visit!

          aggregate_failures do
            expect(page).not_to have_content(notifications(private_group, :limit_overage_enforcement_msg))
            # total user is 6, but 1 is an invited group member
            expect { private_group.list_members.count }.to eventually_eq(5)
          end

          private_group.add_member(user_7)

          expect { private_group.list_members.count }.to eventually_eq(6)
        end

        it(
          'new group enforcement removed when trial started',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387827'
        ) do
          create_private_group_with_members
          page.refresh

          expect { page }
            .to eventually_have_content(notifications(private_group, :limit_reached_enforcement_msg))
                  .within(max_attempts: 5, sleep_interval: 2, reload_page: page)

          Gitlab::Page::Trials::New.perform(&:visit)
          Flow::Trial.register_for_trial
          private_group.visit!

          expect(page).not_to have_content(notifications(private_group, :limit_reached_enforcement_msg))
        end

        it(
          'enforcement does not allow adding more members',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387828'
        ) do
          create_private_group_with_members

          # Checks that it fails to add an additional member due to enforcement
          begin
            private_group.add_member(user_7)
          rescue Support::Repeater::RetriesExceededError
            expect { private_group.list_members.count }.to eventually_eq(5)
          end
        end

        it(
          'enforcement limit counts includes invited group and project members',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/387829'
        ) do
          project.add_member(user_2)
          private_group.add_member(user_3)
          invitee_group.add_members(user_4, user_5, user_6)

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

      # group_owner is also counted, free user member limit for a new private group is 5
      def create_private_group_with_members
        private_group.add_members(user_2, user_3, user_4, user_5)
      end

      def send_private_group_over_limit
        invitee_group.add_member(user_6)
        private_group.invite_group(invitee_group)
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
            "Your top-level group #{group.path} will move to a read-only state soon
             Because you are over the 5 user limit, your top-level group, including any subgroups
             and projects, will be placed in a read-only state soon",
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
