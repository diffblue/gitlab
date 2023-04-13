# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::AfterCreateService, feature_category: :code_review_workflow do
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:project) { merge_request.target_project }

  let(:service_object) { described_class.new(project: project, current_user: merge_request.author) }

  describe '#execute' do
    subject(:execute) { service_object.execute(merge_request) }

    before do
      allow(Ci::SyncReportsToReportApprovalRulesWorker).to receive(:perform_async)
      allow(Security::ScanResultPolicies::SyncFindingsToApprovalRulesWorker).to receive(:perform_async)
    end

    context 'when the merge request has actual_head_pipeline' do
      let(:pipeline_id) { 1881 }

      before do
        allow(merge_request).to receive(:head_pipeline_id).and_return(pipeline_id)
        allow(merge_request).to receive(:update_head_pipeline).and_return(true)
      end

      it 'schedules a background job to sync security reports and findngs to approval rules' do
        execute

        expect(merge_request).to have_received(:update_head_pipeline).ordered
        expect(Ci::SyncReportsToReportApprovalRulesWorker).to have_received(:perform_async).ordered.with(pipeline_id)
        expect(Security::ScanResultPolicies::SyncFindingsToApprovalRulesWorker)
          .to have_received(:perform_async).ordered.with(pipeline_id)
      end

      context 'when sync_approval_rules_from_findings is disabled' do
        before do
          stub_feature_flags(sync_approval_rules_from_findings: false)
        end

        it 'does not schedule a background job to sync findings to approval rules' do
          execute

          expect(Security::ScanResultPolicies::SyncFindingsToApprovalRulesWorker).not_to have_received(:perform_async)
        end
      end
    end

    context 'when the merge request does not have actual_head_pipeline' do
      it 'does not schedule a background job to sync security reports and findings to approval rules' do
        execute

        expect(Ci::SyncReportsToReportApprovalRulesWorker).not_to have_received(:perform_async)
        expect(Security::ScanResultPolicies::SyncFindingsToApprovalRulesWorker).not_to have_received(:perform_async)
      end
    end

    describe 'suggested reviewers' do
      before do
        allow(MergeRequests::FetchSuggestedReviewersWorker).to receive(:perform_async)
        allow(merge_request).to receive(:ensure_merge_request_diff)
      end

      context 'when suggested reviewers is available for project' do
        before do
          allow(project).to receive(:can_suggest_reviewers?).and_return(true)
        end

        context 'when merge request can suggest reviewers' do
          before do
            allow(merge_request).to receive(:can_suggest_reviewers?).and_return(true)
          end

          it 'calls fetch worker for the merge request' do
            execute

            expect(merge_request).to have_received(:ensure_merge_request_diff).ordered
            expect(MergeRequests::FetchSuggestedReviewersWorker).to have_received(:perform_async)
              .with(merge_request.id)
              .ordered
          end
        end

        context 'when merge request cannot suggest reviewers' do
          before do
            allow(merge_request).to receive(:can_suggest_reviewers?).and_return(false)
          end

          it 'does not call fetch worker for the merge request' do
            execute

            expect(MergeRequests::FetchSuggestedReviewersWorker).not_to have_received(:perform_async)
          end
        end
      end

      context 'when suggested reviewers is not available for project' do
        before do
          allow(project).to receive(:can_suggest_reviewers?).and_return(false)
        end

        context 'when merge request can suggest reviewers' do
          before do
            allow(merge_request).to receive(:can_suggest_reviewers?).and_return(true)
          end

          it 'does not call fetch worker for the merge request' do
            execute

            expect(MergeRequests::FetchSuggestedReviewersWorker).not_to have_received(:perform_async)
          end
        end
      end
    end
  end
end
