# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::SyncFindingsToApprovalRulesService, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let_it_be(:target_pipeline) { create(:ee_ci_pipeline, project: project, ref: merge_request.target_branch) }
  let_it_be(:pipeline) do
    create(:ee_ci_pipeline,
      project: project,
      merge_requests_as_head_pipeline: [merge_request]
    )
  end

  describe '#execute' do
    subject(:execute) { described_class.new(pipeline).execute }

    context 'when pipeline_findings is empty and pipeline is complete' do
      it 'does not call UpdateApprovalsService' do
        expect(Security::ScanResultPolicies::UpdateApprovalsService).not_to receive(:new)

        execute
      end
    end

    context 'when pipeline_findings is not empty or pipeline is not complete' do
      let_it_be(:pipeline_scan) { create(:security_scan, pipeline: pipeline) }
      let_it_be(:pipeline_findings) do
        create(:security_finding, scan: pipeline_scan, severity: 'high')
      end

      it 'calls UpdateApprovalsService for merge request' do
        expect(Security::ScanResultPolicies::UpdateApprovalsService).to receive(:new).with(
          merge_request: merge_request,
          pipeline: pipeline,
          pipeline_findings: pipeline.security_findings
        ).and_call_original

        execute
      end
    end
  end
end
