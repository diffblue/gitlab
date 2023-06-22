# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BlockService, feature_category: :user_management do
  let_it_be(:current_user) { create(:admin) }

  subject(:service) { described_class.new(current_user) }

  describe '#execute' do
    let!(:user) { create(:user) }

    subject(:operation) { service.execute(user) }

    describe 'audit events' do
      context 'when licensed' do
        before do
          stub_licensed_features(admin_audit_log: true)
        end

        context 'when user block operation succeeds' do
          it 'logs an audit event', :aggregate_failures do
            expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including({
              name: 'user_blocked'
            })).and_call_original

            expect { operation }.to change { AuditEvent.count }.by(1)

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
              custom_message: "Blocked user"
            })
          end
        end

        context 'when user block operation fails' do
          before do
            allow(user).to receive(:block).and_return(false)
          end

          it 'does not log any audit event' do
            expect { operation }.not_to change { AuditEvent.count }
          end
        end
      end

      context 'when not licensed' do
        before do
          stub_licensed_features(
            admin_audit_log: false,
            audit_events: false,
            extended_audit_events: false
          )
        end

        it 'does not log any audit event' do
          expect { operation }.not_to change(AuditEvent, :count)
        end
      end
    end
  end
end
