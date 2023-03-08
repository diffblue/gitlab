# frozen_string_literal: true

require "spec_helper"

RSpec.describe MergeRequests::Mergeability::CheckApprovedService, feature_category: :code_review_workflow do
  subject(:check_approved) { described_class.new(merge_request: merge_request, params: {}) }

  let_it_be(:merge_request) { build(:merge_request) }

  describe "#execute" do
    let(:result) { check_approved.execute }

    before do
      expect(merge_request).to receive(:approved?).and_return(approved)
    end

    context "when the merge request is approved" do
      let(:approved) { true }

      it "returns a check result with status success" do
        expect(result.status)
          .to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end

    context "when the merge request is not approved" do
      let(:approved) { false }

      it "returns a check result with status failure" do
        expect(result.status)
          .to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        expect(result.payload[:reason]).to eq(:not_approved)
      end
    end
  end

  describe '#skip?' do
    it 'returns false' do
      expect(check_approved.skip?).to eq false
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_approved.cacheable?).to eq false
    end
  end
end
