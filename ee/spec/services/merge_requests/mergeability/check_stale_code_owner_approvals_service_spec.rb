# frozen_string_literal: true

require "spec_helper"

RSpec.describe MergeRequests::Mergeability::CheckStaleCodeOwnerApprovalsService,
  feature_category: :code_review_workflow do
  subject(:stale_approval_check) { described_class.new(merge_request: merge_request, params: {}) }

  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:user) { create(:user) }
  let_it_be(:code_owner_rule) { create(:code_owner_rule, merge_request: merge_request, users: [user]) }
  let_it_be(:approval) { create(:approval, merge_request: merge_request, user: user) }

  describe "#execute" do
    let(:result) { stale_approval_check.execute }

    context "when approvals are selectively resettable" do
      before do
        allow(stale_approval_check).to receive(:selective_code_owner_removals?).and_return(true)
      end

      it "returns success if there are no eligible (resettable) approvals" do
        expect(stale_approval_check).to receive(:eligible_approvals).and_return([])
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end
  end

  describe "#eligible_approvals" do
    let(:eligible_approvals) { stale_approval_check.send(:eligible_approvals) }

    context "when #selective_code_owner_removals? is true" do
      before do
        allow(stale_approval_check).to receive(:selective_code_owner_removals?).and_return(true)
      end

      it "returns [] when there are no #approved_code_owner_rules" do
        expect(stale_approval_check).to receive(:approved_code_owner_rules).and_return([])
        expect(eligible_approvals).to eq([])
      end

      context "when #approval_feature_available? is true" do
        before do
          allow(merge_request).to receive(:approval_feature_available?).and_return(true)
        end

        it "matches approvals to code owner rules" do
          expect(::Gitlab::CodeOwners).to receive(:entries_since_merge_request_commit).and_call_original
          eligible_approvals
        end
      end
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
