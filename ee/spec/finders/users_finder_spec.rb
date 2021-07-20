# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersFinder do
  describe '#execute' do
    include_context 'UsersFinder#execute filter by project context'

    context 'with a normal user' do
      context 'with LDAP users' do
        let_it_be(:ldap_user) { create(:omniauth_user, provider: 'ldap') }

        it 'returns ldap users by default' do
          users = described_class.new(normal_user).execute

          expect(users).to contain_exactly(normal_user, blocked_user, omniauth_user, external_user, ldap_user, internal_user, admin_user)
        end

        it 'returns only non-ldap users with skip_ldap: true' do
          users = described_class.new(normal_user, skip_ldap: true).execute

          expect(users).to contain_exactly(normal_user, blocked_user, omniauth_user, external_user, internal_user, admin_user)
        end
      end

      context 'with SAML users' do
        let_it_be(:group) { create(:group) }
        let_it_be(:saml_provider) { create(:saml_provider, group: group, enabled: true, enforced_sso: true) }
        let_it_be(:saml_user) { create(:user) }
        let_it_be(:non_saml_user) { create(:user) }

        before do
          create(:identity, provider: 'group_saml1', saml_provider_id: saml_provider.id, user: saml_user)
        end

        it 'returns all users by default' do
          users = described_class.new(normal_user).execute

          expect(users).to contain_exactly(normal_user, blocked_user, omniauth_user, external_user, internal_user, admin_user, saml_user, non_saml_user)
        end

        it 'returns only saml users from the provided saml_provider_id' do
          users = described_class.new(normal_user, by_saml_provider_id: saml_provider.id).execute

          expect(users).to contain_exactly(saml_user)
        end
      end
    end
  end
end
