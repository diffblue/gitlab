# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::ExternalStatusCheckChangesAuditor do
  describe 'auditing external status check changes' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:external_status_check) do
      create(:external_status_check,
             name: 'QA',
             external_url: 'http://examplev1.com',
             project: project)
    end

    let_it_be(:external_status_check_changes_auditor) { described_class.new(user, external_status_check) }

    before do
      stub_licensed_features(extended_audit_events: true)
    end

    let(:subject) { described_class.new(user, project.external_status_checks) }

    context 'when audit change happens' do
      it 'creates an event when the name changes' do
        external_status_check.update!(name: 'QAv2')

        expect { external_status_check_changes_auditor.execute }.to change { AuditEvent.count }.by(1)
        expect(AuditEvent.last.details).to include({
                                                     change: 'name',
                                                     from: 'QA',
                                                     to: 'QAv2'
                                                   })
      end

      it 'creates an event when the external url changes' do
        external_status_check.update!(external_url: 'http://examplev2.com')

        expect { external_status_check_changes_auditor.execute }.to change { AuditEvent.count }.by(1)
        expect(AuditEvent.last.details).to include({
                                                     change: 'external url',
                                                     from: 'http://examplev1.com',
                                                     to: 'http://examplev2.com'
                                                   })
      end
    end
  end
end
