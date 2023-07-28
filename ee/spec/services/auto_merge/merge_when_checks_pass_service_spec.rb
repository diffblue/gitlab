# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoMerge::MergeWhenChecksPassService, feature_category: :code_review_workflow do
  using RSpec::Parameterized::TableSyntax

  include_context 'for auto_merge strategy context'

  let(:approval_rule) do
    create(:approval_merge_request_rule, merge_request: mr_merge_if_green_enabled,
      approvals_required: approvals_required)
  end

  describe '#available_for?' do
    subject { service.available_for?(mr_merge_if_green_enabled) }

    let_it_be(:approver) { create(:user) }

    before do
      create(:ci_pipeline, pipeline_status,
        ref: mr_merge_if_green_enabled.source_branch,
        sha: mr_merge_if_green_enabled.diff_head_sha,
        project: mr_merge_if_green_enabled.source_project)
      mr_merge_if_green_enabled.update_head_pipeline

      approval_rule.users << approver
    end

    context 'when feature flag "merge_when_checks_pass" is enabled' do
      before do
        stub_feature_flags(merge_when_checks_pass: project)
      end

      where(:pipeline_status, :approvals_required, :result) do
        :running | 0 | true
        :success | 0 | false
        :running | 1 | true
        :success | 1 | true
      end

      with_them do
        it { is_expected.to eq result }
      end
    end

    context 'when feature flag "merge_when_checks_pass" is disabled' do
      before do
        stub_feature_flags(merge_when_checks_pass: false)
      end

      where(:pipeline_status, :approvals_required, :result) do
        :running | 0 | false
        :success | 0 | false
        :running | 1 | false
        :success | 1 | false
      end

      with_them do
        it { is_expected.to eq result }
      end
    end

    context 'when the user does not have permission to merge' do
      let(:pipeline_status) { :running }
      let(:approvals_required) { 0 }

      before do
        allow(mr_merge_if_green_enabled).to receive(:can_be_merged_by?).and_return(false)
      end

      it { is_expected.to eq false }
    end

    context 'when there is an open MR dependency' do
      let(:pipeline_status) { :running }
      let(:approvals_required) { 0 }

      before do
        stub_licensed_features(blocking_merge_requests: true)
        create(:merge_request_block, blocked_merge_request: mr_merge_if_green_enabled)
      end

      it { is_expected.to eq false }
    end
  end

  describe "#execute" do
    it_behaves_like 'auto_merge service #execute' do
      let(:auto_merge_strategy) { AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS }
      let(:expected_note) do
        "enabled an automatic merge when all merge checks for #{pipeline.sha} pass"
      end
    end
  end

  describe "#process" do
    it_behaves_like 'auto_merge service #process' do
      context 'when pipeline has succeeded and approvals are required' do
        let_it_be(:approver1) { create(:user) }
        let_it_be(:approver2) { create(:user) }
        let(:approvals_required) { 2 }
        let(:triggering_pipeline) do
          create(:ci_pipeline, :success, project: project, ref: merge_request_ref,
            sha: merge_request_head,
            head_pipeline_of: mr_merge_if_green_enabled)
        end

        before do
          allow(mr_merge_if_green_enabled)
            .to receive_messages(head_pipeline: triggering_pipeline, actual_head_pipeline: triggering_pipeline)
          approval_rule.users += [approver1, approver2]
        end

        context 'when all required approvals are given' do
          before do
            create(:approval, merge_request: mr_merge_if_green_enabled, user: approver1)
            create(:approval, merge_request: mr_merge_if_green_enabled, user: approver2)
          end

          it 'merges the merge request' do
            expect(MergeWorker).to receive(:perform_async)

            service.process(mr_merge_if_green_enabled)
          end
        end

        context 'when some approvals are missing' do
          before do
            create(:approval, merge_request: mr_merge_if_green_enabled, user: approver1)
          end

          it 'does not merge request' do
            expect(MergeWorker).not_to receive(:perform_async)

            service.process(mr_merge_if_green_enabled)
          end
        end
      end
    end
  end

  describe '#cancel' do
    it_behaves_like 'auto_merge service #cancel'
  end

  describe '#abort' do
    it_behaves_like 'auto_merge service #abort'
  end
end
