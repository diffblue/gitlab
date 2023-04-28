# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :requires_admin,
    product_group: :utilization, feature_flag: { name: 'saas_user_caps', scope: :group },
    only: { pipeline: %i[staging staging-canary] } do
    describe 'Utilization' do
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:hash) { SecureRandom.hex(8) }
      let(:user_2) { Resource::User.fabricate_via_api! { |user| user.api_client = admin_api_client } }
      let(:user_3) { Resource::User.fabricate_via_api! { |user| user.api_client = admin_api_client } }

      let(:group) do
        Resource::Sandbox.fabricate! do |sandbox|
          sandbox.path = "fulfillment-private-group-#{hash}"
          sandbox.api_client = admin_api_client
        end
      end

      before do
        Runtime::Feature.enable(:saas_user_caps, group: group)

        Flow::Login.sign_in_as_admin
        group.visit!
        Page::Group::Menu.perform(&:click_group_general_settings_item)
        Page::Group::Settings::General.perform do |settings|
          settings.set_saas_user_cap_limit(2)
        end
        group.add_members(user_2, user_3)
      end

      context 'when admin sets user cap limit for group' do
        it(
          'shows members over limit as pending for approvals',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/407170'
        ) do
          expect(group.list_all_members.count).to eq(3)
          expect { membership_state_count(group, 'active') }
            .to eventually_eq(2).within(max_duration: 10, sleep_interval: 1)
          expect(membership_state_count(group, 'awaiting')).to eq(1)

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

      context 'when admin removes user cap limit for group' do
        it(
          'does not automatically approve pending members',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/407172'
        ) do
          expect { membership_state_count(group, 'awaiting') }
            .to eventually_eq(1).within(max_duration: 10, sleep_interval: 1)

          Page::Group::Settings::General.perform do |settings|
            settings.set_saas_user_cap_limit('')
          end

          expect { membership_state_count(group, 'awaiting') }
            .to eventually_eq(1).within(max_duration: 10, sleep_interval: 1)
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
