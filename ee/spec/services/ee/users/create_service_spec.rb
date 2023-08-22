# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::CreateService, feature_category: :user_management do
  let_it_be(:current_user) { create(:admin) }

  let(:params) do
    {
      name: 'John Doe',
      username: 'jduser',
      email: 'jd@example.com',
      password: User.random_password
    }
  end

  subject(:service) { described_class.new(current_user, params) }

  describe '#execute' do
    context "when licenesed" do
      before do
        stub_licensed_features(extended_audit_events: true)
      end

      context 'audit events' do
        it 'logs the audit event info' do
          expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(
            name: 'user_created'
          )).and_call_original

          # user creation will also send confirmaiton instructions which is also audited
          allow(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(name: 'email_confirmation_sent'))

          user = service.execute

          expect(AuditEvent.last).to have_attributes(
            author_id: current_user.id,
            entity_id: user.id,
            entity_type: 'User',
            details: {
              add: 'user',
              author_class: 'User',
              author_name: current_user.name,
              custom_message: "User #{user.username} created",
              target_id: user.id,
              target_type: 'User',
              target_details: user.full_path,
              registration_details: {
                id: user.id,
                name: user.name,
                username: user.username,
                email: user.email,
                access_level: user.access_level
              }
            }
          )
        end

        it 'does not log audit event if operation fails' do
          expect_any_instance_of(User).to receive(:save).and_return(false)

          expect { service.execute }.not_to change { AuditEvent.count }
        end

        it 'does not log audit event if operation results in no change' do
          service.execute

          expect { service.execute }.not_to change(AuditEvent, :count)
        end
      end

      context 'when audit is not required' do
        let(:current_user) { nil }

        it 'does not log any audit event' do
          allow(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(name: 'email_created'))

          expect { service.execute }.not_to change(AuditEvent, :count)
        end
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

    it 'does not log audit event' do
      expect { service.execute }.not_to change(AuditEvent, :count)
    end
  end
end
