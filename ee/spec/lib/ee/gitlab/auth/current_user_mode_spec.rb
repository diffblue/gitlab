# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::CurrentUserMode, :request_store do
  let_it_be(:user) { create(:user, :admin) }

  subject { described_class.new(user) }

  context 'when session is available' do
    include_context 'custom session'

    before do
      allow(ActiveSession).to receive(:list_sessions).with(user).and_return([session])
    end

    describe '#enable_admin_mode!' do
      before do
        stub_licensed_features(extended_audit_events: true)
      end

      context 'when enabling admin mode succeeds' do
        it 'creates an audit event', :aggregate_failures do
          subject.request_admin_mode!

          expect do
            subject.enable_admin_mode!(password: user.password)
          end.to change { AuditEvent.count }.by(1)

          expect(AuditEvent.last).to have_attributes(
            author: user,
            entity: user,
            target_id: user.id,
            target_type: user.class.name,
            target_details: user.name,
            details: include(custom_message: 'Enabled admin mode')
          )
        end
      end

      context 'when enabling admin mode fails' do
        it 'does not create an audit event' do
          subject.request_admin_mode!

          expect do
            subject.enable_admin_mode!(password: 'wrong password')
          end.not_to change { AuditEvent.count }
        end
      end
    end
  end
end
