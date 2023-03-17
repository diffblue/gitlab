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
      let(:options) { { model: user, event_type: 'audit_operation' } }

      it 'calls the auditor' do
        user.update!(name: 'Scrooge McDuck')

        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
          { additional_details: { change: :name,
                                  from: "Donald Duck",
                                  to: "Scrooge McDuck" },
            name: 'audit_operation',
            author: current_user,
            scope: user,
            target: user,
            message: "Changed name from Donald Duck to Scrooge McDuck",
            target_details: nil }
        )

        audit!
      end

      it 'creates audit event with correct attributes', :aggregate_failures do
        user.update!(name: 'Scrooge McDuck')

        audit!

        audit_event = AuditEvent.last

        expect(audit_event.author_id).to eq(current_user.id)
        expect(audit_event.entity_id).to eq(user.id)
        expect(audit_event.entity_type).to eq(user.class.name)
        expect(audit_event.details).to eq({ change: :name,
                                            author_name: current_user.name,
                                            author_class: current_user.class.name,
                                            from: "Donald Duck",
                                            to: "Scrooge McDuck",
                                            target_details: user.name,
                                            target_id: user.id,
                                            target_type: user.class.name,
                                            custom_message: "Changed name from Donald Duck to Scrooge McDuck" })
      end
    end
  end
end
