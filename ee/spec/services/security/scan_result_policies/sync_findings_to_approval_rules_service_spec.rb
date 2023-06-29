# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::SyncFindingsToApprovalRulesService, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let_it_be(:target_pipeline) { create(:ee_ci_pipeline, project: project, ref: merge_request.target_branch) }
  let_it_be(:pipeline) do
    create(:ee_ci_pipeline,
      project: project,
      ref: merge_request.source_branch,
      sha: project.commit(merge_request.source_branch).sha,
      merge_requests_as_head_pipeline: [merge_request]
    )
  end

  shared_examples 'calls UpdateApprovalsService' do
    it do
      expect(Security::ScanResultPolicies::UpdateApprovalsService).to receive(:new).with(
        merge_request: merge_request,
        pipeline: pipeline
      ).and_call_original

      execute
    end
  end

  shared_examples 'does not call UpdateApprovalsService' do
    it do
      expect(Security::ScanResultPolicies::UpdateApprovalsService).not_to receive(:new)

      execute
    end
  end

  describe '#execute' do
    subject(:execute) { described_class.new(pipeline).execute }

    context 'when pipeline_findings is empty' do
      it_behaves_like 'does not call UpdateApprovalsService'
    end

    context 'when pipeline is not complete' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :running, project: project) }

      it_behaves_like 'does not call UpdateApprovalsService'
    end

    context 'when pipeline_findings is not empty' do
      let_it_be(:pipeline_scan) { create(:security_scan, pipeline: pipeline) }
      let_it_be(:pipeline_findings) do
        create(:security_finding, scan: pipeline_scan, severity: 'high')
      end

      it_behaves_like 'calls UpdateApprovalsService'

      context 'when multi_pipeline_scan_result_policies is disabled' do
        before do
          stub_feature_flags(multi_pipeline_scan_result_policies: false)
        end

        it_behaves_like 'calls UpdateApprovalsService'
      end

      context 'when merge_request is closed' do
        before do
          merge_request.update!(state_id: MergeRequest.available_states[:closed])
        end

        it_behaves_like 'does not call UpdateApprovalsService'
      end

      context 'when pipeline is not latest' do
        let_it_be(:pipeline) do
          create(:ee_ci_pipeline, project: project, ref: merge_request.source_branch)
        end

        it_behaves_like 'does not call UpdateApprovalsService'
      end
    end
  end
end
