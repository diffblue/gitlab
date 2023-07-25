# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::DestroyService, feature_category: :user_profile do
  let!(:user) { create(:user) }
  let!(:email) { create(:email, user: user) }

  subject(:service) { described_class.new(user, user: user) }

  describe '#execute' do
    it 'creates audit event' do
      stub_licensed_features(extended_audit_events: true)

      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including({
        name: 'email_destroyed'
      })).and_call_original

      expect { service.execute(email) }.to change { AuditEvent.count }.by(1)

      audit_event = AuditEvent.last
      expect(audit_event.author).to eq(user)
      expect(audit_event.entity).to eq(user)
      expect(audit_event.target_type).to eq("Email")
      expect(audit_event.details).to include({
        remove: "email",
        author_name: user.name,
        target_type: "Email"
      })
    end
  end
end
