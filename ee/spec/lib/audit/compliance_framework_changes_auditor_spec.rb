# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::ComplianceFrameworkChangesAuditor do
  describe 'auditing compliance framework changes' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:destination) { create(:external_audit_event_destination, group: group) }

    let(:project) { create(:project, group: group) }
    let(:subject) { described_class.new(user, project.compliance_framework_setting, project) }

    before do
      project.reload
      stub_licensed_features(extended_audit_events: true, external_audit_events: true)
    end

    context 'when a project has no compliance framework' do
      context 'when the framework is added' do
        let_it_be(:framework) { create(:compliance_framework) }

        before do
          project.update!(compliance_management_framework: framework)
        end

        it 'adds an audit event' do
          expect { subject.execute }.to change(AuditEvent, :count).by(1)
          expect(AuditEvent.last.details).to include({
                                                       change: 'compliance framework',
                                                       from: 'None',
                                                       to: 'GDPR'
                                                     })
        end

        it 'streams correct audit event stream' do
          expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(
            'compliance_framework_id_updated', anything, anything)

          subject.execute
        end
      end
    end

    context 'when a project has a compliance framework' do
      let_it_be(:framework) { create(:compliance_framework) }

      before do
        project.update!(compliance_management_framework: framework)
      end

      context 'when the framework is removed' do
        before do
          project.update!(compliance_management_framework: nil)
        end

        it 'adds an audit event' do
          expect { subject.execute }.to change(AuditEvent, :count).by(1)
          expect(AuditEvent.last.details).to include({
                                                       custom_message: "Unassigned project compliance framework"
                                                     })
        end

        it 'streams correct audit event stream' do
          expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(
            'compliance_framework_deleted', anything, anything)

          subject.execute
        end
      end

      context 'when the framework is changed' do
        before do
          project.update!(compliance_management_framework:
            create(:compliance_framework, namespace: project.group, name: 'SOX'))
        end

        it 'adds an audit event' do
          expect { subject.execute }.to change(AuditEvent, :count).by(1)
          expect(AuditEvent.last.details).to include({
                                                       change: 'compliance framework',
                                                       from: 'GDPR',
                                                       to: 'SOX'
                                                     })
        end
      end
    end

    context 'when the framework is not changed' do
      before do
        project.update!(description: 'This is a description of a project')
      end

      it 'does not add an audit event' do
        expect { subject.execute }.not_to change(AuditEvent, :count)
      end
    end
  end
end
