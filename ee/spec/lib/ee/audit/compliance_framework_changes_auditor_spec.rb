# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Audit::ComplianceFrameworkChangesAuditor do
  describe 'auditing compliance framework changes' do
    let_it_be(:user) { create(:user) }

    let(:project) { create(:project) }

    before do
      project.reload
      stub_licensed_features(extended_audit_events: true)
    end

    let(:subject) { described_class.new(user, project.compliance_framework_setting, project) }

    context 'when a project has no compliance framework' do
      context 'when the framework is added' do
        let_it_be(:framework) { create(:compliance_framework) }

        before do
          project.update!(compliance_management_framework: framework)
        end

        it 'adds an audit event' do
          expect { subject.execute }.to change { AuditEvent.count }.by(1)
          expect(AuditEvent.last.details).to include({
                                                       change: 'compliance framework',
                                                       from: 'None',
                                                       to: 'GDPR'
                                                     })
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
          expect { subject.execute }.to change { AuditEvent.count }.by(1)
          expect(AuditEvent.last.details).to include({
                                                       custom_message: "Unassigned project compliance framework"
                                                     })
        end
      end

      context 'when the framework is changed' do
        before do
          project.update!(compliance_management_framework: create(:compliance_framework, namespace: project.namespace, name: 'SOX'))
        end

        it 'adds an audit event' do
          expect { subject.execute }.to change { AuditEvent.count }.by(1)
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
        expect { subject.execute }.not_to change { AuditEvent.count }
      end
    end
  end
end
