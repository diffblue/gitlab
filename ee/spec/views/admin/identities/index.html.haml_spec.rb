# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/identities/index.html.haml', :aggregate_failures do
  include Admin::IdentitiesHelper

  let_it_be(:group) { create(:group) }
  let_it_be(:saml_provider) { create(:saml_provider, group: group) }
  let_it_be(:saml_user, refind: true) { create(:user) }
  let_it_be(:saml_identity) do
    create(
      :identity, provider: 'group_saml', saml_provider_id: saml_provider.id, user: saml_user, extern_uid: 'saml-uid'
    )
  end

  before do
    assign(:user, saml_user)
    view.lookup_context.prefixes = ['admin/identities']
  end

  context 'without SCIM or other identities' do
    before do
      assign(:identities, [])
    end

    it 'shows information text' do
      render

      expect(rendered).to include('<td colspan="5">').exactly(1)
      expect(rendered).to include(_('This user has no identities'))
    end
  end

  context 'with SCIM identities' do
    before_all do
      create(:scim_identity, group: group, extern_uid: 'scim-uid', user: saml_user)
      assign(:identities, [])
    end

    it 'shows exactly 5 columns' do
      render

      expect(rendered).to include('</td>').exactly(5)
    end

    it 'shows identity without provider ID' do
      render

      # Provider
      expect(rendered).to include('SCIM')
      # Provider ID
      expect(rendered).to include('data-testid="provider_id_blank"')
      # Group
      expect(rendered).to include("<a href=\"/#{group.path}\">#{group.path}</a>")
      # Identifier
      expect(rendered).to include('scim-uid')
    end

    it 'shows no edit or delete identity buttons' do
      render

      expect(rendered).not_to include("aria-label=\"#{_('Edit')}\"")
      expect(rendered).not_to include("aria-label=\"#{_('Delete identity')}\"")
    end
  end

  context 'with SAML identities' do
    before do
      assign(:identities, saml_identity)
    end

    it 'shows exactly 5 columns' do
      render

      expect(rendered).to include('</td>').exactly(5)
    end

    it 'shows identity with provider ID or group' do
      render

      # Provider
      expect(rendered).to include('Group Saml (group_saml)')
      # Provider ID
      expect(rendered).to include("data-testid=\"provider_id_#{saml_provider.id}\"")
      # Group
      expect(rendered).to include("<a href=\"/#{group.path}\">#{group.path}</a>")
      # Identifier
      expect(rendered).to include('saml-uid')
    end

    it 'shows edit and delete identity buttons' do
      render

      expect(rendered).to include("aria-label=\"#{_('Edit')}\"")
      expect(rendered).to include("aria-label=\"#{_('Delete identity')}\"")
    end
  end
end
