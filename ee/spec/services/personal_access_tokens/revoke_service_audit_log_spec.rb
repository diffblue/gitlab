# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::RevokeService, feature_category: :system_access do
  describe '#execute' do
    subject { service.execute }

    let(:user) { create(:user) }
    let(:token) { create(:personal_access_token, user: user) }
    let(:service) { described_class.new(user, token: token) }

    it 'creates audit events' do
      audit_context = {
        name: 'personal_access_token_revoked',
        author: user,
        scope: user,
        target: user,
        message: "Revoked personal access token with id #{token.id}"
      }

      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)
        .and_call_original

      subject
    end
  end
end
