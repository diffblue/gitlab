# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::UserImpersonationGroupAuditEventService do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  let(:service) { described_class.new(impersonator: admin, user: user, remote_ip: '111.112.11.2', action: :started, created_at: 3.weeks.ago) }

  before do
    stub_licensed_features(audit_events: true)
    stub_licensed_features(admin_audit_log: true)
    stub_licensed_features(extended_audit_events: true)
  end

  context 'when user belongs to a single group' do
    before do
      group.add_developer(user)
    end

    it 'creates audit events for both the instance and group level' do
      freeze_time do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).twice.with(hash_including({
          name: "user_impersonation"
        })).and_call_original

        expect { service.execute }.to change { AuditEvent.count }.by(2)

        event = AuditEvent.first
        expect(event.details[:custom_message]).to eq("Started Impersonation")
        expect(event.created_at).to eq(3.weeks.ago)

        group_audit_event = AuditEvent.last
        expect(group_audit_event.details[:custom_message]).to eq("Instance administrator started impersonation of #{user.username}")
        expect(group_audit_event.created_at).to eq(3.weeks.ago)
      end
    end
  end

  context 'when user belongs to multiple groups' do
    let!(:group2) { create(:group) }
    let!(:group3) { create(:group) }

    before do
      group.add_developer(user)
      group2.add_developer(user)
      group3.add_developer(user)
    end

    it 'creates audit events for both the instance and group level' do
      expect { service.execute }.to change { AuditEvent.count }.by(4)

      event = AuditEvent.first
      expect(event.details[:custom_message]).to eq("Started Impersonation")

      group_audit_event = AuditEvent.last
      expect(group_audit_event.details[:custom_message]).to eq("Instance administrator started impersonation of #{user.username}")
    end
  end

  context 'when user does not belong to any group' do
    it 'creates audit events at the instance level' do
      expect { service.execute }.to change { AuditEvent.count }.by(1)

      event = AuditEvent.last
      expect(event.details[:custom_message]).to eq("Started Impersonation")
      expect(event.author).to eq admin
      expect(event.target_id).to eq user.id
    end
  end
end
