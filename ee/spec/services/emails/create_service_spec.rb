# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::CreateService, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  let(:opts) { { email: 'new@email.com', user: user } }

  subject(:service) { described_class.new(user, opts) }

  describe '#execute' do
    it 'creates an audit event' do
      stub_licensed_features(extended_audit_events: true)

      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including({
        name: 'email_created'
      })).and_call_original

      expect { service.execute }.to change { AuditEvent.count }.by(1)

      expect(AuditEvent.last).to have_attributes(
        author: user,
        entity: user,
        target_type: "Email",
        details: hash_including({
          add: "email",
          author_name: user.name,
          target_type: "Email"
        })
      )
    end
  end
end
