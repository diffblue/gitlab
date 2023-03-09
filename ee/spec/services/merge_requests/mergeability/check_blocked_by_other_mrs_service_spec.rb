# frozen_string_literal: true

require "spec_helper"

RSpec.describe MergeRequests::Mergeability::CheckBlockedByOtherMrsService, feature_category: :code_review_workflow do
  subject(:check_blocked_by_other_mrs) { described_class.new(merge_request: merge_request, params: {}) }

  let(:merge_request) { build(:merge_request) }

  let_it_be(:blocking_merge_request) { build(:merge_request) }

  describe "#execute" do
    let(:result) { check_blocked_by_other_mrs.execute }

    context "when blocking_merge_requests feature is unavailable" do
      before do
        stub_licensed_features(blocking_merge_requests: false)
      end

      it "returns a check result with status success" do
        expect(result.status)
          .to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end

    context "when blocking_merge_requests feature is available" do
      before do
        stub_licensed_features(blocking_merge_requests: true)
      end

      context "when there are no blocking MRs" do
        it "returns a check result with status success" do
          expect(result.status)
            .to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
        end
      end

      context "when there are blocking MRs" do
        before do
          expect(merge_request).to receive(:blocking_merge_requests).and_return([blocking_merge_request])
        end

        it "returns a check result with status success" do
          expect(result.status)
            .to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
          expect(result.payload[:reason]).to eq(:merge_request_blocked)
        end
      end
    end
  end

  describe "#skip?" do
    it "returns false" do
      expect(check_blocked_by_other_mrs.skip?).to eq false
    end
  end

  describe "#cacheable?" do
    it "returns false" do
      expect(check_blocked_by_other_mrs.cacheable?).to eq false
    end
  end
end
