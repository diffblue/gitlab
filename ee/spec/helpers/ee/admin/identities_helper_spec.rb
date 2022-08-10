# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::IdentitiesHelper do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:saml_provider) { create(:saml_provider, group: group) }
  let_it_be(:saml_identity) do
    create(:identity, provider: 'group_saml', saml_provider_id: saml_provider.id, user: user,
                      extern_uid: 'saml-uid')
  end

  let_it_be(:ldap_identity) do
    create(:identity, user: user, extern_uid: 'without-saml-uid')
  end

  describe '#provider_id_cell_testid' do
    context 'without SAML provider ID' do
      it 'shows blank provider id for data-testid' do
        expect(helper.provider_id_cell_testid(ldap_identity)).to eq 'provider_id_blank'
      end
    end

    context 'with SAML provider ID' do
      it 'shows provider id for data-testid' do
        expect(helper.provider_id_cell_testid(saml_identity)).to eq "provider_id_#{saml_identity.saml_provider_id}"
      end
    end
  end

  describe '#provider_id' do
    context 'without SAML provider ID' do
      it 'shows no provider id' do
        expect(helper.provider_id(ldap_identity)).to eq '-'
      end
    end

    context 'with SAML provider ID' do
      it 'shows no provider id' do
        expect(helper.provider_id(saml_identity)).to be_an Integer
      end
    end
  end

  describe '#saml_group_cell_testid' do
    context 'without SAML provider' do
      it 'shows blank SAML group for data-testid' do
        expect(helper.saml_group_cell_testid(ldap_identity)).to eq 'saml_group_blank'
      end
    end

    context 'with SAML provider' do
      it 'shows no SAML group for data-testid' do
        expect(helper.saml_group_cell_testid(saml_identity)).to be_nil
      end
    end
  end

  describe '#saml_group_link' do
    context 'without SAML provider' do
      it 'shows no link to SAML group' do
        expect(helper.saml_group_link(ldap_identity)).to eq '-'
      end
    end

    context 'with SAML provider' do
      it 'shows link to SAML group' do
        expect(helper.saml_group_link(saml_identity)).to eq "<a href=\"/#{group.path}\">#{group.path}</a>"
      end
    end
  end
end
