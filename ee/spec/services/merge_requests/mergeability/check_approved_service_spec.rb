# frozen_string_literal: true

require "spec_helper"

RSpec.describe MergeRequests::Mergeability::CheckApprovedService do
  subject(:check_approved) { described_class.new(merge_request: merge_request, params: {}) }

  let(:merge_request) { build(:merge_request) }

  describe "#execute" do
    before do
      expect(merge_request).to receive(:approved?).and_return(approved)
    end

    context "when the merge request is approved" do
      let(:approved) { true }

      it "returns a check result with status success" do
        expect(check_approved.execute.status)
          .to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end

    context "when the merge request is not approved" do
      let(:approved) { false }

      it "returns a check result with status failure" do
        expect(check_approved.execute.status)
          .to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
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
