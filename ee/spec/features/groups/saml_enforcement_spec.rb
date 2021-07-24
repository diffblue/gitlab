# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SAML access enforcement' do
  let(:group) { create(:group, :private, name: 'The Group Name') }
  let(:sub_group) { create(:group, :private, name: 'The Subgroup Name', parent: group) }
  let(:project) { create(:project, :private, name: 'The Project Name', namespace: group) }
  let(:sub_group_project) { create(:project, name: 'The Subgroup Project Name', group: sub_group) }
  let(:saml_provider) { create(:saml_provider, group: group, enforced_sso: true) }
  let(:identity) { create(:group_saml_identity, saml_provider: saml_provider) }
  let(:user) { identity.user }

  before do
    group.add_guest(user)
    sign_in(user)

    stub_licensed_features(group_saml: true)
  end

  context 'without SAML session' do
    shared_examples 'resource access' do
      before do
        visit resource_path
      end

      it 'prevents access to resource via SSO redirect' do
        expect(page).to have_content("SAML SSO Sign in to \"#{group.name}\"")
        expect(current_url).to match(%r{groups/#{group.to_param}/-/saml/sso\?redirect=.+&token=})
      end
    end

    context 'group resources' do
      it_behaves_like 'resource access' do
        let(:resource_path) { group_path(group) }
      end
    end

    context 'subgroup resources' do
      it_behaves_like 'resource access' do
        let(:resource_path) { group_path(sub_group) }
      end
    end

    context 'project resources' do
      it_behaves_like 'resource access' do
        let(:resource_path) { project_path(project) }
      end
    end

    context 'subgroup project resources' do
      it_behaves_like 'resource access' do
        let(:resource_path) { project_path(sub_group_project) }
      end
    end
  end

  context 'with active SAML login from session' do
    shared_examples 'resource access' do
      before do
        dummy_session = { active_group_sso_sign_ins: { saml_provider.id => DateTime.now } }
        allow(Gitlab::Session).to receive(:current).and_return(dummy_session)

        visit resource_path
      end

      it 'allows access to resource' do
        expect(page).not_to have_content('Page Not Found')
        expect(page).not_to have_content('SAML SSO Sign')
        expect(page).to have_content(resource_name)
        expect(current_path).to eq(resource_path)
      end
    end

    context 'group resources' do
      it_behaves_like 'resource access' do
        let(:resource_path) { group_path(group) }
        let(:resource_name) { group.name }
      end
    end

    context 'subgroup resources' do
      it_behaves_like 'resource access' do
        let(:resource_path) { group_path(sub_group) }
        let(:resource_name) { sub_group.name }
      end
    end

    context 'project resources' do
      it_behaves_like 'resource access' do
        let(:resource_path) { project_path(project) }
        let(:resource_name) { project.name }
      end
    end

    context 'subgroup project resources' do
      it_behaves_like 'resource access' do
        let(:resource_path) { project_path(sub_group_project) }
        let(:resource_name) { sub_group_project.name }
      end
    end
  end

  context 'when SAML session expires' do
    before do
      mock_group_saml(uid: identity.extern_uid)
    end

    it 'shows loading screen and link used for auto-redirect' do
      visit group_path(group)

      click_link 'Sign in with Single Sign-On'

      days_after_timeout = Gitlab::Auth::GroupSaml::SsoEnforcer::DEFAULT_SESSION_TIMEOUT + 2.days
      travel_to(days_after_timeout.from_now) do
        visit group_path(group)

        expect(page).to have_content('Reauthenticating with SAML provider.')
        expect(page).to have_selector('#js-auto-redirect-to-provider', visible: false)
      end
    end

    context 'with a merge request' do
      let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
      let(:resource_path) { project_merge_request_path(project, merge_request) }

      it 'redirects to the SSO page and then merge request page after login' do
        visit resource_path

        expect(current_url).to include("redirect=#{CGI.escape(resource_path)}")

        click_link 'Sign in with Single Sign-On'

        expect(current_path).to eq(resource_path)
      end
    end
  end
end
