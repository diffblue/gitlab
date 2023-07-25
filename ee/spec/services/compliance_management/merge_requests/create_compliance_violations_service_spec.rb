# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::MergeRequests::CreateComplianceViolationsService,
  feature_category: :compliance_management do
  # Works around https://gitlab.com/gitlab-org/gitlab/-/issues/335054
  let_it_be_with_refind(:unmerged_merge_request) { create(:merge_request) }
  let_it_be_with_refind(:merged_merge_request) { create(:merge_request, :merged) }

  shared_examples 'does not call process_merge_request' do
    subject { described_class.new(merged_merge_request).execute }

    it :aggregate_failures do
      expect(::MergeRequests::ComplianceViolation).not_to receive(:process_merge_request)

      expect(subject.success?).to be false
      expect(subject.message).to eq 'This group is not permitted to create compliance violations'
    end
  end

  context 'when the compliance center feature is disabled' do
    before do
      stub_licensed_features(group_level_compliance_dashboard: false)
    end

    it_behaves_like 'does not call process_merge_request'
  end

  context 'when the compliance center feature is enabled' do
    before do
      stub_licensed_features(group_level_compliance_dashboard: true)
    end

    context 'and the merge request is not merged', :aggregate_failures do
      subject { described_class.new(unmerged_merge_request).execute }

      it 'does not call process_merge_request' do
        expect(::MergeRequests::ComplianceViolation).not_to receive(:process_merge_request)

        expect(subject.success?).to be false
        expect(subject.message).to eq 'Merge request not merged'
      end
    end

    context 'and the merge request is merged' do
      subject { described_class.new(merged_merge_request).execute }

      it 'calls process_merge_request', :aggregate_failures do
        expect(::MergeRequests::ComplianceViolation).to receive(:process_merge_request).with(merged_merge_request)

        expect(subject.success?).to be true
        expect(subject.message).to eq 'Created compliance violations if any were found'
      end
    end
  end
end
