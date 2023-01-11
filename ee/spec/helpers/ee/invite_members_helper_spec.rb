# frozen_string_literal: true
require 'spec_helper'

RSpec.describe EE::InviteMembersHelper do
  include Devise::Test::ControllerHelpers

  describe '#common_invite_group_modal_data' do
    let_it_be(:project) { create(:project) }
    let_it_be(:group) { create(:group, :private, projects: [project]) }

    before do
      stub_ee_application_setting(dashboard_limit_enabled: true)
      stub_ee_application_setting(dashboard_limit: 5)
    end

    it 'has expected common attributes' do
      expect(helper.common_invite_group_modal_data(project, ProjectMember, 'true'))
        .to include({ free_user_cap_enabled: 'true', free_users_limit: 5 })
    end
  end

  describe '#common_invite_modal_dataset', :saas do
    let(:project) { build(:project) }

    before do
      stub_ee_application_setting(dashboard_limit_enabled: true)
    end

    context 'when applying the free user cap is not valid' do
      let!(:group) do
        create(:group_with_plan, :private, projects: [project], plan: :default_plan)
      end

      it 'does not include users limit notification data' do
        expect(helper.common_invite_modal_dataset(project)).not_to have_key(:users_limit_dataset)
      end
    end

    context 'when applying the free user cap is valid' do
      let!(:group) do
        create(:group_with_plan, :private, projects: [project], plan: :free_plan)
      end

      let(:expected_alert_data) do
        {
          'alert_variant' => expected_variant,
          'free_users_limit' => ::Namespaces::FreeUserCap.dashboard_limit,
          'remaining_seats' => expected_remaining_seats,
          'new_trial_registration_path' => new_trial_path,
          'purchase_path' => group_billings_path(project.root_ancestor),
          'members_path' => group_usage_quotas_path(project.root_ancestor)
        }
      end

      let(:users_limit_dataset) do
        Gitlab::Json.parse(helper.common_invite_modal_dataset(project)[:users_limit_dataset])
      end

      context 'with feature flag :preview_free_user_cap enabled' do
        let(:expected_remaining_seats) { 0 }

        before do
          stub_feature_flags(preview_free_user_cap: true)
          stub_feature_flags(free_user_cap: false)
        end

        context 'when notifying the free user cap limit' do
          context 'when not over limit' do
            let(:expected_variant) { nil }

            it 'includes correct users limit notification data' do
              expect(users_limit_dataset).to eq(expected_alert_data)
            end
          end

          context 'when over limit' do
            let_it_be(:user) { create(:user) }

            let(:expected_variant) { 'notification' }

            before do
              group.add_owner(user)
            end

            it 'includes correct users limit notification data' do
              expect(users_limit_dataset).to eq(expected_alert_data)
            end
          end
        end
      end

      context 'with feature flag :free_user_cap enabled' do
        before do
          stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: 2.days.ago)

          stub_feature_flags(preview_free_user_cap: false)
          stub_feature_flags(free_user_cap: true)
        end

        context 'when not close to or over the free user cap limit' do
          let(:expected_variant) { nil }
          let(:expected_remaining_seats) { 5 }

          before do
            stub_ee_application_setting(dashboard_limit: 5)
          end

          it 'includes correct users limit notification data' do
            expect(users_limit_dataset).to eq(expected_alert_data)
          end
        end

        context 'when close to the free user cap limit' do
          let(:expected_variant) { 'close' }
          let(:expected_remaining_seats) { 1 }

          before do
            stub_ee_application_setting(dashboard_limit: 1)
          end

          it 'includes correct users limit notification data' do
            expect(users_limit_dataset).to eq(expected_alert_data)
          end
        end

        context 'when at the free user cap limit' do
          let(:expected_variant) { 'reached' }
          let(:expected_remaining_seats) { 0 }

          it 'includes correct users limit notification data' do
            expect(users_limit_dataset).to eq(expected_alert_data)
          end
        end
      end
    end
  end

  describe '#users_filter_data' do
    let_it_be(:group) { create(:group) }
    let_it_be(:saml_provider) { create(:saml_provider, group: group) }

    let!(:group2) { create(:group) }

    context 'when the group has enforced sso' do
      before do
        allow(group).to receive(:enforced_sso?).and_return(true)
      end

      context 'when there is a group with a saml provider' do
        it 'returns user filter data' do
          expected = { users_filter: 'saml_provider_id', filter_id: saml_provider.id }

          expect(helper.users_filter_data(group)).to eq expected
        end
      end

      context 'when there is a group without a saml provider' do
        it 'does not return user filter data' do
          expect(helper.users_filter_data(group2)).to eq({})
        end
      end
    end

    context 'when group has enforced sso disabled' do
      before do
        allow(group).to receive(:enforced_sso?).and_return(false)
      end

      context 'when there is a group with a saml provider' do
        it 'does not return user filter data' do
          expect(helper.users_filter_data(group)).to eq({})
        end
      end

      context 'when there is a group without a saml provider' do
        it 'does not return user filter data' do
          expect(helper.users_filter_data(group2)).to eq({})
        end
      end
    end
  end
end
