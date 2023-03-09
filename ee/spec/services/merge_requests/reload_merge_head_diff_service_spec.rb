# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ReloadMergeHeadDiffService, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }

  subject { described_class.new(merge_request).execute }

  describe '#execute' do
    before do
      MergeRequests::MergeToRefService
        .new(project: merge_request.project, current_user: merge_request.author)
        .execute(merge_request)
    end

    context 'code_owners feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      context 'when reloading was successful' do
        context 'when merge request is not on a merge train' do
          it 'syncs code owner approval rules' do
            sync_service = instance_double(MergeRequests::SyncCodeOwnerApprovalRules)
            expect(sync_service).to receive(:execute)
            expect(MergeRequests::SyncCodeOwnerApprovalRules).to receive(:new)
              .with(merge_request)
              .and_return(sync_service)
            expect(subject[:status]).to eq(:success)
          end
        end

        context 'when merge request is on a merge train' do
          let(:merge_request) { create(:merge_request, :on_train) }

          it 'does not sync code owner approval rules' do
            expect(MergeRequests::SyncCodeOwnerApprovalRules).not_to receive(:new)
            expect(subject[:status]).to eq(:success)
          end
        end
      end

      context 'when reloading failed' do
        before do
          allow(merge_request).to receive(:create_merge_head_diff!).and_raise('fail')
        end

        it 'does not sync code owner approval rules' do
          expect(MergeRequests::SyncCodeOwnerApprovalRules).not_to receive(:new)
          expect(subject[:status]).to eq(:error)
        end
      end
    end

    context 'code_owners feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      context 'when reloading was successful' do
        it 'syncs code owner approval rules' do
          expect(MergeRequests::SyncCodeOwnerApprovalRules).not_to receive(:new)
          expect(subject[:status]).to eq(:success)
        end
      end
    end
  end
end
