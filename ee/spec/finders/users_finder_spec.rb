# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersFinder do
  describe '#execute' do
    include_context 'UsersFinder#execute filter by project context'

    shared_examples 'executes users finder' do |as_admin: false|
      let_it_be(:normal_users) { [normal_user, unconfirmed_user, omniauth_user, external_user, internal_user, admin_user] }
      let_it_be(:users_visible_to_admin) { as_admin ? [blocked_user, banned_user] : [] }

      context 'with LDAP users' do
        let_it_be(:ldap_user) { create(:omniauth_user, provider: 'ldap') }

        it 'returns ldap users by default' do
          users = described_class.new(user).execute

          expect(users).to contain_exactly(ldap_user, *normal_users, *users_visible_to_admin)
        end

        it 'returns only non-ldap users with skip_ldap: true' do
          users = described_class.new(user, skip_ldap: true).execute

          expect(users).to contain_exactly(*normal_users, *users_visible_to_admin)
        end
      end

      context 'with SAML users' do
        let_it_be(:group) { create(:group) }
        let_it_be(:saml_provider) { create(:saml_provider, group: group, enabled: true, enforced_sso: true) }
        let_it_be(:saml_user) { create(:user) }
        let_it_be(:non_saml_user) { create(:user) }
        let_it_be(:instance_service_account) { create(:service_account) }
        let_it_be(:service_account) { create(:service_account, provisioned_by_group: group) }
        let_it_be(:other_service_account) { create(:service_account, provisioned_by_group: create(:group)) }

        before do
          create(:identity, provider: 'group_saml1', saml_provider_id: saml_provider.id, user: saml_user)
        end

        it 'returns all users' do
          users = described_class.new(user).execute

          expect(users).to contain_exactly(
            saml_user,
            non_saml_user,
            instance_service_account,
            service_account,
            other_service_account,
            *normal_users,
            *users_visible_to_admin
          )
        end

        it 'returns saml users and service accounts for the SAML provider and associated group' do
          users = described_class.new(user, saml_provider_id: saml_provider.id).execute

          expect(users).to contain_exactly(saml_user, service_account)
        end
      end

      context 'with auditor users' do
        before do
          stub_licensed_features(auditor_user: true)
        end

        let_it_be(:group) { create(:group) }
        let_it_be(:auditor_user) { create(:user, :auditor) }
        let_it_be(:non_auditor_user) { create(:user) }
        let_it_be(:auditors_visible_to_admin) { as_admin ? [auditor_user] : [auditor_user, non_auditor_user, *normal_users, *users_visible_to_admin] }

        it 'returns all users by default' do
          users = described_class.new(user).execute

          expect(users).to contain_exactly(auditor_user, non_auditor_user, *normal_users, *users_visible_to_admin)
        end

        it 'returns only auditor users when auditors param is supplied' do
          users = described_class.new(user, auditors: true).execute

          expect(users).to contain_exactly(*auditors_visible_to_admin)
        end
      end
    end

    context 'with a normal user' do
      let_it_be(:user) { normal_user }

      it_behaves_like 'executes users finder'
    end

    context 'with an admin user' do
      let_it_be(:user) { admin_user }

      context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
        it_behaves_like 'executes users finder', as_admin: true
      end

      context 'when admin mode setting is enabled' do
        context 'when in admin mode', :enable_admin_mode do
          it_behaves_like 'executes users finder', as_admin: true
        end

        context 'when not in admin mode' do
          it_behaves_like 'executes users finder'
        end
      end
    end
  end
end
