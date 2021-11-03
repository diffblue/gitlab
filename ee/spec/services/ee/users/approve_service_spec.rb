# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ApproveService do
  let_it_be(:current_user) { create(:admin) }

  subject(:service) { described_class.new(current_user) }

  describe '#execute', :enable_admin_mode do
    let!(:user) { create(:user, :blocked_pending_approval) }

    subject(:operation) { service.execute(user) }

    describe 'audit events' do
      context 'when licensed' do
        before do
          stub_licensed_features(admin_audit_log: true)
        end

        context 'when user approve operation succeeds' do
          it 'logs an audit event' do
            expect { operation }.to change { AuditEvent.count }.by(1)
          end

          it 'logs the audit event info', :aggregate_failures do
            operation

            audit_event = AuditEvent.where(author_id: current_user.id).last

            expect(audit_event.ip_address).to eq(current_user.current_sign_in_ip)
            expect(audit_event.details[:target_details]).to eq(user.username)
            expect(audit_event.details[:custom_message]).to eq('Instance access request approved')
          end
        end

        context 'when user approve operation fails' do
          before do
            allow(user).to receive(:activate).and_return(false)
          end

          it 'does not log any audit event' do
            expect { operation }.not_to change { AuditEvent.count }
          end
        end
      end
    end
  end
end
