# frozen_string_literal: true
require 'spec_helper'

RSpec.describe EE::InviteMembersHelper do
  include Devise::Test::ControllerHelpers

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

    context 'when on free plan' do
      let!(:group) do
        create(:group_with_plan, :private, projects: [project], plan: :free_plan)
      end

      it 'includes users limit notification data' do
        result = {
          'free_users_limit' => ::Namespaces::FreeUserCap.dashboard_limit,
          'reached_limit' => true,
          'close_to_dashboard_limit' => false,
          'remaining_seats' => 0,
          'new_trial_registration_path' => new_trial_path,
          'purchase_path' => group_billings_path(project.root_ancestor),
          'members_path' => group_usage_quotas_path(project.root_ancestor)
        }

        users_limit_dataset = Gitlab::Json.parse(helper.common_invite_modal_dataset(project)[:users_limit_dataset])

        expect(users_limit_dataset).to eq(result)
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
