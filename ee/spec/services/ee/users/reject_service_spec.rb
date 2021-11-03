# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::RejectService do
  let_it_be(:current_user) { create(:admin) }

  describe '#execute', :enable_admin_mode do
    let_it_be_with_reload(:user) { create(:user, :blocked_pending_approval) }

    subject(:reject_user) { Users::RejectService.new(current_user).execute(user) }

    context 'audit events' do
      context 'when licensed' do
        before do
          stub_licensed_features(admin_audit_log: true)
        end

        context 'when user is successfully rejected' do
          it 'logs an audit event' do
            expect { reject_user }.to change { AuditEvent.count }.by(1)
          end

          it 'logs the audit event info', :aggregate_failures do
            reject_user
            audit_event = AuditEvent.where(author_id: current_user.id).last

            expect(audit_event.ip_address).to eq(current_user.current_sign_in_ip)
            expect(audit_event.details[:target_details]).to eq(user.username)
            expect(audit_event.details[:custom_message]).to eq('Instance access request rejected')
          end
        end

        context 'when user does not have permission to reject another user' do
          let_it_be(:current_user) { create(:user) }

          it 'does not log any audit event' do
            expect { reject_user }.not_to change { AuditEvent.count }
          end
        end
      end
    end
  end
end
