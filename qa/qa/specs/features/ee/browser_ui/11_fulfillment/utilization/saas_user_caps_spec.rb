# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment',
    :requires_admin,
    product_group: :utilization,
    feature_flag: {
      name: 'saas_user_caps',
      scope: :group
    },
    only: { pipeline: %i[staging staging-canary] } do
    describe 'Utilization' do
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:hash) { SecureRandom.hex(8) }
      let(:user_2) { create(:user, api_client: admin_api_client) }
      let(:user_3) { create(:user, api_client: admin_api_client) }

      let(:group) do
        Resource::Sandbox.fabricate! do |sandbox|
          sandbox.path = "fulfillment-user-caps-group-#{hash}"
          sandbox.api_client = admin_api_client
        end
      end

      before do
        Runtime::Feature.enable(:saas_user_caps, group: group)

        Flow::Login.sign_in_as_admin
        group.visit!
        Page::Group::Menu.perform(&:go_to_general_settings)
        Page::Group::Settings::General.perform do |settings|
          settings.set_saas_user_cap_limit(2)
        end

        group.add_member(user_2)
      end

      after do
        group&.remove_via_api!
      end

      context 'when admin sets user cap limit for group' do
        it(
          'shows members over limit as pending for approvals',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/407170'
        ) do
          # Sometimes there is a delay when setting the SaaS user cap limit
          # due to the application cache interval, so we need to retry adding
          # the extra group member again if the limit had not taken effect yet
          Support::Retrier.retry_until(
            max_duration: 70,
            retry_on_exception: true,
            sleep_interval: 3,
            message: "Waiting for membership state to update"
          ) do
            group.remove_member(user_3) if group.find_member(user_3.username).present?

            group.add_member(user_3)

            membership_state_count(group, 'active') == 2 && membership_state_count(group, 'awaiting') == 1
          end

          Page::Group::Menu.perform(&:go_to_usage_quotas)
          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            expect { usage_quota.pending_members_alert }
              .to eventually_match(/You have 1 pending member that needs approval/i)
                    .within(max_duration: 10, reload_page: page)
            usage_quota.view_pending_approvals
            expect(usage_quota.pending_members).to match(/#{user_3.name}/)

            usage_quota.approve_member
            usage_quota.confirm_member_approval

            expect { membership_state_count(group, 'active') }
              .to eventually_eq(3).within(max_duration: 10, sleep_interval: 1)
          end
        end
      end

      private

      # Returns member count that have specific membership state
      #
      # @param [Resource::Sandbox] group
      # @param [String] state
      def membership_state_count(group, state)
        group.list_all_members.pluck(:membership_state).count(state)
      end
    end
  end
end
