# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TwoFactor::DestroyService do
  let_it_be(:current_user) { create(:user, :two_factor) }

  subject(:disable_2fa) { described_class.new(current_user, user: current_user).execute }

  context 'when disabling two-factor authentication succeeds' do
    context 'when licensed' do
      before do
        stub_licensed_features(admin_audit_log: true, audit_events: true, extended_audit_events: true)
      end
      it 'creates an audit event', :aggregate_failures do
        expect { disable_2fa }.to change(AuditEvent, :count).by(1)

        expect(AuditEvent.last).to have_attributes(
          author: current_user,
          entity_id: current_user.id,
          target_id: current_user.id,
          target_type: current_user.class.name,
          target_details: current_user.name,
          details: include(custom_message: 'Disabled two-factor authentication')
        )
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(admin_audit_log: false, audit_events: false, extended_audit_events: false)
      end

      it 'does not track audit event' do
        expect { disable_2fa }.not_to change { AuditEvent.count }
      end
    end
  end

  context 'when disabling two-factor authentication fails' do
    before do
      allow_next_instance_of(Users::UpdateService) do |instance|
        allow(instance).to receive(:execute)
              .and_return({ status: :error })
      end
    end

    it 'does not create an audit event' do
      expect { subject }.not_to change(AuditEvent, :count)
    end
  end
end
