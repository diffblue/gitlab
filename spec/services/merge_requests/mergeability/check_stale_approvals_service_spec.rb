# frozen_string_literal: true

require "spec_helper"

RSpec.describe MergeRequests::Mergeability::CheckStaleApprovalsService,
  feature_category: :code_review_workflow do
  subject(:stale_approval_check) { described_class.new(merge_request: merge_request, params: {}) }

  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:approval) { create(:approval, merge_request: merge_request, user: user) }

  describe "#execute" do
    let(:result) { stale_approval_check.execute }

    context "when #reset_approvals_on_push? is true" do
      before do
        allow(stale_approval_check).to receive(:reset_approvals_on_push?).and_return(true)
      end

      context "when the approvals are up to date" do
        it "returns a check result with status success" do
          expect(merge_request.approved_by?(user)).to be_truthy
          expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
        end
      end

      context "when the approvals are against an outdated commit" do
        it "returns a check result with status failed" do
          expect(merge_request).to receive(:diff_head_sha).at_least(:once).and_return("someStaleSHA")
          create(:approval, merge_request: merge_request, user: create(:user))

          expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
          expect(result.payload[:reason]).to eq(:stale_approvals)
        end
      end
    end

    context "when #reset_approvals_on_push? is false" do
      before do
        allow(stale_approval_check).to receive(:reset_approvals_on_push?).and_return(false)
      end

      it "returns a check result with status success" do
        expect(merge_request.approved_by?(user)).to be_truthy
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end

      it "doesn't call #all_approvals_current?" do
        expect(subject).not_to receive(:all_approvals_current?)
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end
  end

  describe "#eligible_approvals" do
    let(:eligible_approvals) { stale_approval_check.send(:eligible_approvals) }

    it "returns all approvals for the merge request" do
      expect(eligible_approvals).to eq(merge_request.approvals)
    end
  end

  describe "#skip?" do
    it "returns false" do
      expect(stale_approval_check.skip?).to eq false
    end
  end

  describe "#cacheable?" do
    it "returns false" do
      expect(stale_approval_check.cacheable?).to eq false
    end
  end
end
