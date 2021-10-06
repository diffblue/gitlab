# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestComplianceEntity do
  include Gitlab::Routing

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, :merged) }

  let(:request) { double('request', current_user: user, project: project) }
  let(:entity) { described_class.new(merge_request.reload, request: request) }

  describe '.as_json' do
    subject { entity.as_json }

    it 'includes merge request attributes for compliance' do
      expect(subject).to include(
        :id,
        :title,
        :merged_at,
        :milestone,
        :path,
        :issuable_reference,
        :reference,
        :author,
        :approved_by_users,
        :committers,
        :participants,
        :merged_by,
        :approval_status,
        :target_branch,
        :target_branch_uri,
        :source_branch,
        :source_branch_uri,
        :compliance_management_framework,
        :project
      )
    end

    it 'builds the merge request metrics' do
      expect_any_instance_of(MergeRequestMetricsHelper) do |instance|
        expect(instance).to receive(:build_metrics).with(merge_request)
      end

      subject
    end

    describe 'with an approver' do
      let_it_be(:approver) { create(:user) }
      let_it_be(:approval) { create :approval, merge_request: merge_request, user: approver }

      before_all do
        project.add_developer(approver)
      end

      it 'includes only set of approver details' do
        expect(subject[:approved_by_users].count).to eq(1)
      end

      it 'includes approver user details' do
        expect(subject[:approved_by_users][0][:id]).to eq(approver.id)
      end
    end

    describe 'with a head pipeline' do
      let_it_be(:pipeline) { create(:ci_empty_pipeline, status: :success, project: project, head_pipeline_of: merge_request) }

      describe 'and the user cannot read the pipeline' do
        it 'does not include pipeline status attribute' do
          expect(subject).not_to have_key(:pipeline_status)
        end
      end

      describe 'and the user can read the pipeline' do
        before do
          project.add_developer(user)
        end

        it 'includes pipeline status attribute' do
          expect(subject).to have_key(:pipeline_status)
        end
      end
    end

    context 'with an approval status' do
      let_it_be(:committers_approval_enabled) { false }
      let_it_be(:authors_approval_enabled) { false }
      let_it_be(:approvals_required) { 2 }

      shared_examples 'the approval status' do
        before do
          allow(merge_request).to receive(:authors_can_approve?).and_return(authors_approval_enabled)
          allow(merge_request).to receive(:committers_can_approve?).and_return(committers_approval_enabled)
          allow(merge_request).to receive(:approvals_required).and_return(approvals_required)
        end

        it 'is correct' do
          expect(subject[:approval_status]).to eq(status)
        end
      end

      context 'all approval checks pass' do
        let_it_be(:status) { :success }

        it_behaves_like 'the approval status'
      end

      context 'only some of the approval checks pass' do
        let_it_be(:authors_approval_enabled) { true }
        let_it_be(:status) { :warning }

        it_behaves_like 'the approval status'
      end

      context 'none of the approval checks pass' do
        let_it_be(:committers_approval_enabled) { true }
        let_it_be(:authors_approval_enabled) { true }
        let_it_be(:approvals_required) { 0 }
        let_it_be(:status) { :failed }

        it_behaves_like 'the approval status'
      end
    end
  end
end
