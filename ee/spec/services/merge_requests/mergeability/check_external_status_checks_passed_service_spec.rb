# frozen_string_literal: true

require "spec_helper"

RSpec.describe MergeRequests::Mergeability::CheckExternalStatusChecksPassedService,
  feature_category: :code_review_workflow do
  using RSpec::Parameterized::TableSyntax

  subject(:check_external_status_checks_passed_service) do
    described_class.new(merge_request: merge_request, params: {})
  end

  let(:merge_request) { build(:merge_request) }

  describe "#execute" do
    let(:result) { check_external_status_checks_passed_service.execute }

    where(:only_allow_merge_if_all_status_checks_passed_enabled?, :any_external_status_checks_not_passed?, :prevent?) do
      true  | false | false
      false | true  | false
      false | false | false
      true  | true  | true
    end

    with_them do
      before do
        allow(subject).to receive(:only_allow_merge_if_all_status_checks_passed_enabled?)
                            .and_return(only_allow_merge_if_all_status_checks_passed_enabled?)
        allow(merge_request.project).to receive(:any_external_status_checks_not_passed?)
                            .and_return(any_external_status_checks_not_passed?)
      end

      it "returns correct status" do
        if prevent?
          expect(result.status)
            .to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
          expect(result.payload[:reason]).to eq(:status_checks_must_pass)
        else
          expect(result.status).to eq(Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS)
        end
      end
    end
  end

  describe '#only_allow_merge_if_all_status_checks_passed_enabled?' do
    let(:result) { subject.send(:only_allow_merge_if_all_status_checks_passed_enabled?, merge_request.project) }

    where(:license, :column_value, :return_value) do
      false | false | false
      true  | false | false
      false | true  | false
      true  | true  | true
    end

    with_them do
      before do
        stub_licensed_features(external_status_checks: license)
        allow(merge_request.project).to receive(:only_allow_merge_if_all_status_checks_passed).and_return(column_value)
      end

      it 'returns correct value' do
        expect(result).to eq(return_value)
      end
    end
  end

  describe "#skip?" do
    it "returns false" do
      expect(check_external_status_checks_passed_service.skip?).to eq false
    end
  end

  describe "#cacheable?" do
    it "returns false" do
      expect(check_external_status_checks_passed_service.cacheable?).to eq false
    end
  end
end
