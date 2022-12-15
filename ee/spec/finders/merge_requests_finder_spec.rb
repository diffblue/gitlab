# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestsFinder do
  describe '#execute' do
    include_context 'MergeRequestsFinder multiple projects with merge requests context'

    let_it_be(:merged_merge_request) do
      create(:merge_request, :simple, author: user, source_project: project4, target_project: project4,
                                      state: :merged, merge_commit_sha: 'rurebf')
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
