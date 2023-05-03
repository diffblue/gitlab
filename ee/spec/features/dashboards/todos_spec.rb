# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard todos', feature_category: :team_planning do
  let_it_be(:user) { create(:user) }

  let(:page_path) { dashboard_todos_path }

  it_behaves_like 'dashboard ultimate trial callout'

  context 'User has a todo in a epic' do
    let_it_be(:group) { create(:group) }
    let_it_be(:target) { create(:epic, group: group) }
    let_it_be(:note) { create(:note, noteable: target, note: "#{user.to_reference} hello world") }
    let_it_be(:todo) do
      create(:todo, :mentioned,
             user: user,
             project: nil,
             group: group,
             target: target,
             author: user,
             note: note)
    end

    before do
      stub_licensed_features(epics: true)

      group.add_owner(user)
      sign_in(user)

      visit page_path
    end

    it 'has todo present' do
      expect(page).to have_selector('.todos-list .todo', count: 1)
      expect(page).to have_selector('a', text: user.to_reference)
    end
  end

  context 'when the user has todos in an SSO enforced group' do
    let_it_be(:saml_provider) { create(:saml_provider, enabled: true, enforced_sso: true) }
    let_it_be(:restricted_group) { create(:group, saml_provider: saml_provider) }
    let_it_be(:epic_todo) do
      create(:todo, group: restricted_group, user: user, target: create(:epic, group: restricted_group))
    end

    before do
      stub_licensed_features(group_saml: true)
      create(:group_saml_identity, user: user, saml_provider: saml_provider)

      restricted_group.add_owner(user)

      sign_in(user)
    end

    context 'and the session is not active' do
      it 'shows the user an alert', :aggregate_failures do
        visit page_path

        expect(page).to have_content(s_('GroupSAML|Some to-do items may be hidden because your SAML session has expired. Select the group’s path to reauthenticate and view the hidden to-do items.')) # rubocop:disable Layout/LineLength
        expect(page).to have_link(restricted_group.path, href: /#{sso_group_saml_providers_path(restricted_group)}/)
      end
    end

    context 'and the session is active' do
      before do
        dummy_session = { active_group_sso_sign_ins: { saml_provider.id => DateTime.now } }
        allow(Gitlab::Session).to receive(:current).and_return(dummy_session)
      end

      it 'does not show the user an alert', :aggregate_failures do
        visit page_path

        expect(page).not_to have_content(s_('GroupSAML|Some to-do items may be hidden because your SAML session has expired. Select the group’s path to reauthenticate and view the hidden to-do items.')) # rubocop:disable Layout/LineLength
      end
    end
  end
end
