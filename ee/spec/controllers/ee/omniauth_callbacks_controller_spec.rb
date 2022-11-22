# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniauthCallbacksController, type: :controller, feature_category: :authentication_and_authorization do
  include LoginHelpers

  let_it_be(:extern_uid) { 'my-uid' }
  let_it_be(:provider) { :ldap }
  let_it_be(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }

  before do
    mock_auth_hash(provider.to_s, extern_uid, user.email)
    stub_omniauth_provider(provider, context: request)
  end

  context 'when sign in fails' do
    before do
      subject.response = ActionDispatch::Response.new

      allow(subject).to receive(:params)
        .and_return(ActionController::Parameters.new(username: user.username))

      stub_omniauth_failure(
        OmniAuth::Strategies::LDAP.new(nil),
        'invalid_credentials',
        OmniAuth::Strategies::LDAP::InvalidCredentialsError.new('Invalid credentials for ldap')
      )
    end

    it 'audits provider failed login when licensed' do
      stub_licensed_features(extended_audit_events: true)
      expect { subject.failure }.to change { AuditEvent.count }.by(1)
    end

    it 'does not audit provider failed login when unlicensed' do
      stub_licensed_features(extended_audit_events: false)
      expect { subject.failure }.not_to change { AuditEvent.count }
    end
  end
end
