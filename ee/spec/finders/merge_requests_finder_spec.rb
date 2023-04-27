# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestsFinder, feature_category: :code_review_workflow do
  describe '#execute' do
    include_context 'MergeRequestsFinder multiple projects with merge requests context'

    let_it_be(:merged_merge_request) do
      create(
        :merge_request, :simple, author: user, source_project: project4, target_project: project4,
        state: :merged, merge_commit_sha: 'rurebf'
      )
    end

    let_it_be(:approver) { create(:approver, target: merged_merge_request, user: user) }
    let_it_be(:approver_rule) { create(:approval_merge_request_rule, merge_request: merged_merge_request) }

    before do
      approver_rule.users << user
    end

    it 'ignores filtering by weight' do
      params = { project_id: project1.id, scope: 'authored', state: 'opened', weight: Issue::WEIGHT_ANY }

      merge_requests = described_class.new(user, params).execute

      expect(merge_requests).to contain_exactly(merge_request1)
    end

    context 'merge commit sha' do
      it 'filters by merge commit sha' do
        merge_requests = described_class.new(
          user,
          merge_commit_sha: merged_merge_request.merge_commit_sha
        ).execute

        expect(merge_requests).to contain_exactly(merged_merge_request)
      end
    end

    context 'filtering by approved' do
      let_it_be(:project) { create(:project, :public) }

      let_it_be(:author) { create(:user) }
      let_it_be(:approver1) { create(:user) }
      let_it_be(:approver2) { create(:user) }

      let_it_be(:fully_approved_mr) do
        create(:merge_request, author: author, source_project: project, target_project: project, source_branch: 'source-branch-1').tap do |mr|
          create(:approver, target: mr, user: approver1)

          create(:approval, merge_request: mr, user: approver1)
        end
      end

      let_it_be(:partial_approved_mr) do
        create(:merge_request, author: author, source_project: project, target_project: project, source_branch: 'source-branch-2').tap do |mr|
          create(:approver, target: mr, user: approver1)
          create(:approver, target: mr, user: approver2)

          create(:approval, merge_request: mr, user: approver1)
        end
      end

      let_it_be(:not_approved_mr) { create(:merge_request, author: author, source_project: project, target_project: project, source_branch: 'source-branch-3') }

      let_it_be(:approval_rule_with_2_required) do
        create(:approval_merge_request_rule, merge_request: partial_approved_mr, approvals_required: 2)
      end

      let_it_be(:approval_rule_with_1_required) do
        create(:approval_merge_request_rule, merge_request: fully_approved_mr, approvals_required: 1)
      end

      before do
        project.add_developer(approver1)
        project.add_developer(approver2)

        approval_rule_with_2_required.users << approver1
        approval_rule_with_2_required.users << approver2

        approval_rule_with_1_required.users << approver1
      end

      context 'when flag `mr_approved_filter` is enabled' do
        before do
          stub_feature_flags(mr_approved_filter: true)
        end

        context 'when licensed' do
          before do
            stub_licensed_features(merge_request_approvers: true, multiple_approval_rules: true)
          end

          it 'for approved' do
            merge_requests = described_class.new(user, approved: true, source_project_id: project.id).execute

            expect(merge_requests).to contain_exactly(fully_approved_mr)
          end

          it 'for not approved' do
            merge_requests = described_class.new(user, approved: false, source_project_id: project.id).execute

            expect(merge_requests).to contain_exactly(partial_approved_mr, not_approved_mr)
          end
        end

        context 'when unlicensed' do
          before do
            stub_licensed_features(merge_request_approvers: false)
          end

          it 'for approved' do
            merge_requests = described_class.new(user, approved: true, source_project_id: project.id).execute

            expect(merge_requests).to contain_exactly(fully_approved_mr, partial_approved_mr)
          end

          it 'for not approved' do
            merge_requests = described_class.new(user, approved: false, source_project_id: project.id).execute

            expect(merge_requests).to contain_exactly(not_approved_mr)
          end
        end
      end

      context 'when flag `mr_approved_filter` is disabled' do
        before do
          stub_feature_flags(mr_approved_filter: false)
        end

        it 'for approved' do
          merge_requests = described_class.new(user, approved: true, source_project_id: project.id).execute

          expect(merge_requests).to contain_exactly(fully_approved_mr, partial_approved_mr, not_approved_mr)
        end

        it 'for not approved' do
          merge_requests = described_class.new(user, approved: false, source_project_id: project.id).execute

          expect(merge_requests).to contain_exactly(fully_approved_mr, partial_approved_mr, not_approved_mr)
        end
      end
    end

    context 'filtering by approver usernames' do
      let(:params) { { approver_usernames: user.username, sort: 'milestone' } }

      it 'returns merge requests that have user as an approver' do
        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merged_merge_request)
      end

      context 'with nil values' do
        let(:params) { { approver_usernames: nil } }

        it 'returns same set of merge requests without approvers' do
          merge_requests = described_class.new(user, {}).execute

          expect(described_class.new(user, params).execute).to eq(merge_requests)
        end
      end
    end

    context 'filtering by approver user IDs' do
      let(:params) { { approver_ids: user.id, sort: 'milestone' } }

      it 'returns merge requests that have user as an approver' do
        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merged_merge_request)
      end

      context 'with nil values' do
        let(:params) { { approver_ids: nil } }

        it 'returns same set of merge requests without approvers' do
          merge_requests = described_class.new(user, {}).execute

          expect(described_class.new(user, params).execute).to eq(merge_requests)
        end
      end
    end

    context 'filtering by scoped label wildcard' do
      let_it_be(:scoped_label_1) { create(:label, project: project4, title: 'devops::plan') }
      let_it_be(:scoped_label_2) { create(:label, project: project4, title: 'devops::create') }

      let_it_be(:scoped_labeled_merge_request_1) { create(:labeled_merge_request, source_project: project4, source_branch: 'branch1', labels: [scoped_label_1]) }
      let_it_be(:scoped_labeled_merge_request_2) { create(:labeled_merge_request, source_project: project4, source_branch: 'branch2', labels: [scoped_label_2]) }

      before do
        stub_licensed_features(scoped_labels: true)
      end

      it 'returns all merge requests that match the wildcard' do
        merge_requests = described_class.new(user, { project_id: project4.id, label_name: 'devops::*' }).execute

        expect(merge_requests).to contain_exactly(scoped_labeled_merge_request_1, scoped_labeled_merge_request_2)
      end
    end
  end
end
