# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::UserImpersonationEventCreateWorker, feature_category: :audit_events do
  describe "#perform" do
    let_it_be(:impersonator) { create(:admin) }
    let_it_be(:user) { create(:user) }

    let(:action) { :started }

    subject(:worker) { described_class.new }

    it 'invokes the UserImpersonationGroupAuditEventService' do
      freeze_time do
        expect(::AuditEvents::UserImpersonationGroupAuditEventService).to receive(:new).with(
          impersonator: impersonator,
          user: user,
          remote_ip: '111.112.11.2',
          action: action,
          created_at: 2.weeks.ago
        ).and_call_original

        subject.perform(impersonator.id, user.id, '111.112.11.2', action, 2.weeks.ago)
      end
    end
  end
end
