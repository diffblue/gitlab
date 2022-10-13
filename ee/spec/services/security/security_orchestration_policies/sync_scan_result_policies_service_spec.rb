# frozen_string_literal: true

require "spec_helper"

RSpec.describe Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesService do
  let_it_be(:configuration, refind: true) { create(:security_orchestration_policy_configuration, configured_at: nil) }

  describe '#execute' do
    subject { described_class.new(configuration).execute }

    it 'triggers worker for the configuration' do
      expect(Security::ProcessScanResultPolicyWorker).to receive(:perform_async).with(configuration.project_id,
                                                                                      configuration.id)

      subject
    end

    context 'with namespace association' do
      let_it_be(:namespace) { create(:namespace) }
      let_it_be(:project) { create(:project, namespace: namespace) }
      let_it_be(:configuration, refind: true) do
        create(:security_orchestration_policy_configuration, configured_at: nil, project: nil, namespace: namespace)
      end

      it 'triggers worker for the configuration' do
        expect(Security::ProcessScanResultPolicyWorker).to receive(:perform_async).with(project.id, configuration.id)

        subject
      end

      context 'with feature flag disabled' do
        before do
          stub_feature_flags(group_level_scan_result_policies: false)
        end

        it 'does not trigger worker for the configuration' do
          expect(Security::ProcessScanResultPolicyWorker).not_to receive(:perform_async)

          subject
        end

        context 'with existing project approval rules' do
          let_it_be(:mr) { create(:merge_request, :opened, source_project: project) }

          let_it_be(:approval_rule) do
            create(:approval_project_rule,
              :scan_finding,
              project: project,
              security_orchestration_policy_configuration: configuration)
          end

          let_it_be(:scan_finding_mr_rule) do
            create(:report_approver_rule,
              :scan_finding,
              merge_request: mr,
              security_orchestration_policy_configuration: configuration)
          end

          let_it_be(:code_coverage_mr_rule) { create(:report_approver_rule, :code_coverage, merge_request: mr) }

          it 'deletes all project scan_finding approval_rules' do
            expect { subject }.to change(configuration.approval_project_rules, :count).by(-1)
          end

          it 'deletes all merge request scan_finding approval_rules' do
            expect { subject }.to change(configuration.approval_merge_request_rules, :count).by(-1)
          end
        end
      end
    end
  end
end
