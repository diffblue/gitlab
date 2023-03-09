# frozen_string_literal: true

require "spec_helper"

RSpec.describe MergeRequests::Mergeability::CheckDeniedPoliciesService, feature_category: :code_review_workflow do
  subject(:check_denied_policies) { described_class.new(merge_request: merge_request, params: {}) }

  let(:merge_request) { build(:merge_request) }

  describe "#execute" do
    let(:result) { check_denied_policies.execute }

    before do
      expect(merge_request).to receive(:has_denied_policies?).and_return(has_denied_policies)
    end

    context "when the merge request has denied policies" do
      let(:has_denied_policies) { true }

      it "returns a check result with status failed" do
        expect(result.status)
          .to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        expect(result.payload[:reason]).to eq(:policies_denied)
      end
    end

    context "when the merge request does not have denied policies" do
      let(:has_denied_policies) { false }

      it "returns a check result with status success" do
        expect(result.status)
          .to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end
  end

  describe '#skip?' do
    it 'returns false' do
      expect(check_denied_policies.skip?).to eq false
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_denied_policies.cacheable?).to eq false
    end
  end
end
