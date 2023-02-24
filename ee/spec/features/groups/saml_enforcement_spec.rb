# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SAML access enforcement', feature_category: :system_access do
  let(:group) { create(:group, :private, name: 'The Group Name') }
  let(:sub_group) { create(:group, :private, name: 'The Subgroup Name', parent: group) }
  let(:project) { create(:project, :private, name: 'The Project Name', namespace: group) }
  let(:sub_group_project) { create(:project, name: 'The Subgroup Project Name', group: sub_group) }
  let(:saml_provider) { create(:saml_provider, group: group, enforced_sso: true) }
  let(:identity) { create(:group_saml_identity, saml_provider: saml_provider) }
  let(:user) { identity.user }

  # Because the `enforced_sso` option is enabled in the SAML provider, all visits to resources created by the SAML group
  # must be first authenticated through the SAML provider.
  #
  # SSOController::saml shows 3 different buttons depending of the scenario:
  #   a. `Sign in with single sign-on` button: when the user is signed in and has an expired SAML session.
  #      **The button is automatically clicked via JavaScript**. Hence, automatically re-authenticating with the SAML
  #      provider.
  #   b. An `Authorize` button: when the user is signed in but doesn't have a SAML session.
  #   c. A `Sign in` button: when the user is signed out.
  #
  # ATTENTION: SSOController::saml is executed after a redirect! If JavaScript is disabled, `current_user` is lost in
  # the redirection (`nil`) and the SSOController::saml always shows the `Sign in` button (c). If JavaScript is enabled,
  # `current_user` is properly set and SSOController::saml (1) re-authenticates automatically when the user has an
  # expired SAML session (a) or (2) shows the `Authorize` button when the user doesn't have a SAML session (b).

  # This emulate a successful response by the SAML provider
  around do |example|
    with_omniauth_full_host { example.run }
  end

  before do
    group.add_guest(user)
    # Creates a general session but not a SAML session
    sign_in(user)

    stub_licensed_features(group_saml: true)
  end

  shared_examples 'visit resource access via SAML provider' do
    it 'receives callback from SAML providers' do
      expect_next_instance_of(Groups::OmniauthCallbacksController) do |instance|
        expect(instance).to receive(:group_saml).and_call_original
      end

      visit resource_path

      # Capybara's have_current_path matcher checks the path and query string
      expect(page).to have_current_path(resource_path)
    end
  end

  context 'without SAML session' do
    shared_examples 'resource access' do
      before do
        visit resource_path
      end

      it 'prevents access to resource via SSO redirect' do
        expect(page).to have_css("#js-saml-authorize[data-sign-in-button-text='#{_('Sign in')}']")
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
        expect(page.title).not_to have_content(format(_('SAML single sign-on for %{group_name}'),
        group_name: group.name) )
        expect(page).to have_content(resource_name)
        expect(page).to have_current_path(resource_path, ignore_query: true)
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

  context 'when SAML sign-in is mocked', :js do
    let(:resource_path) { group_path(group) }

    before do
      mock_group_saml(uid: identity.extern_uid)
    end

    context 'automatically re-authenticates with SAML provider' do
      it_behaves_like 'visit resource access via SAML provider'
    end

    context 'with an existing SAML session' do
      before do
        # Create a dummy SAML session
        dummy_session = { active_group_sso_sign_ins: { saml_provider.id => DateTime.now } }
        allow(Gitlab::Session).to receive(:current).and_return(dummy_session)
        # Or a real SAML session by visiting the resource_path
        # visit resource_path
      end

      it 'requires re-authentication after session timeout elapses' do
        after_timeout = Gitlab::Auth::GroupSaml::SsoEnforcer::DEFAULT_SESSION_TIMEOUT + 1.second
        travel_to(after_timeout.from_now) do
          expect_next_instance_of(Groups::OmniauthCallbacksController) do |instance|
            expect(instance).to receive(:group_saml).and_call_original
          end

          visit resource_path

          expect(page).to have_current_path(resource_path)
        end
      end
    end

    context 'with a merge request' do
      let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

      context 'redirects to the SSO page and then merge request page after login' do
        it_behaves_like 'visit resource access via SAML provider' do
          let(:resource_path) { project_merge_request_path(project, merge_request, { test: "value" }) }
        end
      end
    end
  end
end
