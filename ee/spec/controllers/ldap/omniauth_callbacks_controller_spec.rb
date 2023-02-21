# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ldap::OmniauthCallbacksController, feature_category: :system_access do
  include_context 'Ldap::OmniauthCallbacksController'

  it "displays LDAP sync flash on first sign in" do
    post provider

    expect(flash[:notice]).to match(/LDAP sync in progress*/)
  end

  it "skips LDAP sync flash on subsequent sign ins" do
    user.update!(sign_in_count: 1)

    post provider

    expect(flash[:notice]).to eq nil
  end

  context 'multiple ldap providers configured' do
    let(:ldap_server_config) do
      {
        main: ldap_config_defaults(:main),
        secondary: ldap_config_defaults(:secondary)
      }
    end

    let(:other_provider) { 'ldapsecondary' }

    context 'multiple ldap servers licensed feature available' do
      let(:multiple_ldap_servers_license_available) { true }

      it 'allows sign in to first provider' do
        post provider

        expect(request.env['warden']).to be_authenticated
      end

      it 'allows sign in to other provider' do
        post other_provider

        expect(request.env['warden']).to be_authenticated
      end
    end

    context 'multiple ldap servers licensed feature not available' do
      let(:multiple_ldap_servers_license_available) { false }

      it 'allows sign in' do
        post provider

        expect(request.env['warden']).to be_authenticated
      end

      it 'does not allow sign in for other providers' do
        post other_provider

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'access denied' do
    let(:valid_login?) { false }

    # This test used to pass on retry only, masking an actual bug. We want to
    # make sure it passes on the first try.
    it 'logs a failure event', retry: 0 do
      stub_licensed_features(extended_audit_events: true)

      expect { post provider }.to change { AuditEvent.count }.by(1)
    end
  end
end
