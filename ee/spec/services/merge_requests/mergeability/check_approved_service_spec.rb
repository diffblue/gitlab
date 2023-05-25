# frozen_string_literal: true

require "spec_helper"

RSpec.describe MergeRequests::Mergeability::CheckApprovedService, feature_category: :code_review_workflow do
  subject(:check_approved) { described_class.new(merge_request: merge_request, params: params) }

  let_it_be(:merge_request) { build(:merge_request) }
  let(:params) { { skip_approved_check: skip_check } }
  let(:skip_check) { false }

  describe "#execute" do
    let(:result) { check_approved.execute }

    before do
      expect(merge_request).to receive(:approved?).and_return(approved)
    end

    context "when the merge request is approved" do
      let(:approved) { true }

      context "with no temporary blocks" do
        it "returns a check result with status success" do
          expect(result.status)
            .to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
        end
      end

      context "with a temporary block" do
        it "returns a check result with status failure" do
          merge_request.approval_state.temporarily_unapprove!

          expect(result.status)
            .to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        end
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
    subject { check_approved.skip? }

    context 'when skip check is true' do
      let(:skip_check) { true }

      it { is_expected.to eq true }
    end

    context 'when skip check is false' do
      let(:skip_check) { false }

      it { is_expected.to eq false }
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_approved.cacheable?).to eq false
    end
  end
end
