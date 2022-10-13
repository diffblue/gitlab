# frozen_string_literal: true

require "spec_helper"

RSpec.describe Security::SecurityOrchestrationPolicies::SyncOpenMergeRequestsHeadPipelineService do
  let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration) }
  let_it_be(:project) { policy_configuration.project }
  let_it_be(:opened_merge_request) { create(:merge_request, :opened, source_project: project) }

  describe "#execute" do
    subject { described_class.new(project: project).execute }

    it 'does not trigger SyncReportsToReportApprovalRulesWorker' do
      expect(::Ci::SyncReportsToReportApprovalRulesWorker).not_to receive(:perform_async)

      subject
    end

    context 'with head_pipeline' do
      let(:head_pipeline) { create(:ci_pipeline, project: project, ref: opened_merge_request.source_branch) }

      before do
        opened_merge_request.update!(head_pipeline_id: head_pipeline.id)
      end

      it 'triggers SyncReportsToReportApprovalRulesWorker' do
        expect(::Ci::SyncReportsToReportApprovalRulesWorker).to receive(:perform_async).with(head_pipeline.id)

        subject
      end
    end
  end
end
