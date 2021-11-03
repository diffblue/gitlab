# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::Changes do
  subject(:foo_instance) { Class.new { include Audit::Changes }.new }

  describe '.audit_changes' do
    let(:current_user) { create(:user, name: 'Mickey Mouse') }
    let!(:user) { create(:user, name: 'Donald Duck') }
    let(:options) { { model: user } }

    subject(:audit!) { foo_instance.audit_changes(:name, options) }

    before do
      stub_licensed_features(extended_audit_events: true)

      foo_instance.instance_variable_set(:@current_user, current_user)
    end

    describe 'non audit changes' do
      context 'when audited column is not changed' do
        it 'does not call the audit event service' do
          user.update!(email: 'scrooge.mcduck@gitlab.com')

          expect { audit! }.not_to change { AuditEvent.count }
        end
      end

      context 'when model is newly created' do
        let(:user) { build(:user) }

        it 'does not call the audit event service' do
          user.update!(name: 'Scrooge McDuck')

          expect { audit! }.not_to change { AuditEvent.count }
        end
      end
    end

    describe 'audit changes' do
      let(:audit_event_service) { instance_spy(AuditEventService) }

      before do
        allow(AuditEventService).to receive(:new).and_return(audit_event_service)
      end

      it 'calls the audit event service' do
        user.update!(name: 'Scrooge McDuck')

        audit!

        aggregate_failures 'audit event service interactions' do
          expect(AuditEventService).to have_received(:new)
            .with(
              current_user, user,
              model: user,
              action: :update, column: :name,
              from: 'Donald Duck', to: 'Scrooge McDuck'
            )
          expect(audit_event_service).to have_received(:for_changes)
          expect(audit_event_service).to have_received(:security_event)
        end
      end

      context 'when entity is provided' do
        let(:project) { Project.new }
        let(:options) { { model: user, entity: project } }

        it 'instantiates audit event service with the given entity' do
          user.update!(name: 'Scrooge McDuck')

          audit!

          expect(AuditEventService).to have_received(:new)
            .with(anything, project, anything)
        end
      end
    end
  end
end
