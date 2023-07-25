# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'VerifiesWithEmail', feature_category: :instance_resiliency do
  let_it_be(:user) { create(:user) }

  subject(:sign_in) do
    post user_session_path, params: { user: { login: user.username, password: user.password } }
  end

  before do
    stub_feature_flags(require_email_verification: user)
    stub_feature_flags(skip_require_email_verification: false)
  end

  context 'when the user is signing in from an unknown ip address' do
    before do
      allow(AuthenticationEvent)
        .to receive(:initial_login_or_known_ip_address?)
        .and_return(false)
    end

    it 'logs a user_access_locked audit event with correct message', feature_category: :audit_events do
      # Stub .audit here so that only relevant audit events are received below
      allow(::Gitlab::Audit::Auditor).to receive(:audit)

      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
        hash_including(
          name: 'user_access_locked',
          message: 'User access locked - sign in from untrusted IP address'
        )
      )

      sign_in
    end

    context 'when the user\'s access is locked' do
      before do
        user.lock_access!
      end

      it 'does not log a user_access_locked audit event with correct message', feature_category: :audit_events do
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit).with(
          hash_including(
            name: 'user_access_locked',
            message: 'User access locked - sign in from untrusted IP address'
          )
        )

        sign_in
      end
    end
  end
end
