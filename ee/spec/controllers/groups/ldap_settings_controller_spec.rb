# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::LdapSettingsController, feature_category: :system_access do
  include LdapHelpers

  let(:group) { create(:group) }
  let(:user)  { create(:user) }

  before do
    stub_ldap_setting(enabled: true)
    stub_feature_flags(ldap_settings_unlock_groups_by_owners: true)

    sign_in(user)
  end

  describe 'PUT #update' do
    describe 'as an owner' do
      before do
        group.add_owner(user)
      end

      describe 'admin allows owners to modify ldap settings' do
        before do
          allow(::Gitlab::CurrentSettings).to receive(:allow_group_owners_to_manage_ldap?).and_return(true)
        end

        it 'changes the value of unlock_membership_to_ldap' do
          expect do
            put :update, params: { group_id: group.to_param, group: { unlock_membership_to_ldap: true } }
          end.to change { group.reload.unlock_membership_to_ldap }
        end

        describe 'ldap_settings_unlock_groups_by_owners is disabled' do
          before do
            stub_feature_flags(ldap_settings_unlock_groups_by_owners: false)
          end

          it 'does not change the value of the unlock_membership_to_ldap' do
            expect do
              put :update, params: { group_id: group.to_param, group: { unlock_membership_to_ldap: true } }
            end.not_to change { group.reload.unlock_membership_to_ldap }
          end
        end
      end

      describe 'admin disallow owners to modify ldap settings' do
        before do
          allow(::Gitlab::CurrentSettings).to receive(:allow_group_owners_to_manage_ldap?).and_return(false)
        end

        it 'does not change the value of unlock_membership_to_ldap' do
          expect do
            put :update, params: { group_id: group.to_param, group: { unlock_membership_to_ldap: true } }
          end.not_to change { group.reload.unlock_membership_to_ldap }
        end
      end
    end

    describe 'as a maintainer' do
      before do
        group.add_maintainer(user)
        allow(::Gitlab::CurrentSettings).to receive(:allow_group_owners_to_manage_ldap?).and_return(true)
      end

      it 'does not change the value of unlock_membership_to_ldap' do
        expect do
          put :update, params: { group_id: group.to_param, group: { unlock_membership_to_ldap: true } }
        end.not_to change { group.reload.unlock_membership_to_ldap }
      end
    end
  end
end
