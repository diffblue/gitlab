# frozen_string_literal: true
require 'spec_helper'

RSpec.describe EE::InviteMembersHelper do
  include Devise::Test::ControllerHelpers

  describe '#common_invite_modal_dataset', :saas do
    let(:project) { build(:project) }

    let(:notification_attributes) do
      {
        free_users_limit: 5,
        members_count: 0,
        new_trial_registration_path: '/-/trials/new',
        purchase_path: "/groups/#{project.root_ancestor.path}/-/billings"
      }
    end

    context 'when applying the free user cap is not valid' do
      let!(:group) do
        build(:group, projects: [project], gitlab_subscription: build(:gitlab_subscription, :default))
      end

      it 'does not include users limit notification data' do
        expect(helper.common_invite_modal_dataset(project)).not_to include(notification_attributes)
      end
    end

    context 'when applying the free user cap is valid' do
      context 'when user namespace' do
        let!(:user_namespace) do
          build(:user_namespace, projects: [project], gitlab_subscription: build(:gitlab_subscription, :free))
        end

        it 'does not include users limit notification data' do
          expect(helper.common_invite_modal_dataset(project)).not_to include(notification_attributes)
        end
      end

      context 'when group namespace' do
        let!(:group) do
          build(:group, projects: [project], gitlab_subscription: build(:gitlab_subscription, :free))
        end

        it 'includes users limit notification data' do
          expect(helper.common_invite_modal_dataset(project)).to include(notification_attributes)
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
