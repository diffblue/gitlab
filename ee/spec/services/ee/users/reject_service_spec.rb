# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::RejectService, feature_category: :user_management do
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
          it 'logs an audit event', :aggregate_failures do
            expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including({
              name: 'user_approved'
            })).and_call_original

            expect { reject_user }.to change { AuditEvent.count }.by(1)

            audit_event = AuditEvent.where(author_id: current_user.id).last

            expect(audit_event.ip_address).to eq(current_user.current_sign_in_ip)
            expect(audit_event.author).to eq(current_user)
            expect(audit_event.entity).to eq(user)
            expect(audit_event.attributes).to include({
              "target_id" => user.id,
              "target_details" => user.username,
              "target_type" => "User"
            })
            expect(audit_event.details).to include({
              target_details: user.username,
              custom_message: "Instance access request rejected"
            })
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
