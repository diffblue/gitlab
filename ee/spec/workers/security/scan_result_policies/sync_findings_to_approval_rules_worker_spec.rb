# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::SyncFindingsToApprovalRulesWorker, feature_category: :security_policy_management do
  let_it_be(:sast_scan) { create(:security_scan, scan_type: :sast) }
  let_it_be(:pipeline) { sast_scan.pipeline }

  describe '#perform' do
    subject(:run_worker) { described_class.new.perform(pipeline.id) }

    let(:can_store_security_reports) { true }

    before do
      allow_next_found_instance_of(Project) do |record|
        allow(record).to receive(:can_store_security_reports?).and_return(can_store_security_reports)
      end
    end

    context 'when security reports cannot be stored for the pipeline' do
      let(:can_store_security_reports) { false }

      context 'when project does not have `any_merge_request` approval rule' do
        it 'does not call SyncFindingsToApprovalRulesService' do
          expect(Security::ScanResultPolicies::SyncFindingsToApprovalRulesService).not_to receive(:new)

          run_worker
        end
      end

      context 'when project has `any_merge_request` approval rule' do
        let(:service) do
          instance_double(Security::ScanResultPolicies::SyncFindingsToApprovalRulesService, execute: nil)
        end

        before do
          create(:approval_project_rule, :any_merge_request, project: pipeline.project)
        end

        it 'does calls SyncFindingsToApprovalRulesService' do
          expect(Security::ScanResultPolicies::SyncFindingsToApprovalRulesService).to receive(:new).and_return(service)

          run_worker
        end
      end
    end

    context 'when security reports can be stored for the pipeline' do
      it 'calls SyncFindingsToApprovalRulesService' do
        expect_next_instance_of(Security::ScanResultPolicies::SyncFindingsToApprovalRulesService, pipeline) do |service|
          expect(service).to receive(:execute)
        end

        run_worker
      end
    end
  end
end
