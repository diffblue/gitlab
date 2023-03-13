# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::MergeRequests::ComplianceViolationsConsistencyService,
  feature_category: :compliance_management do
  describe '#execute' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:project_two) { create(:project, :repository) }
    let_it_be(:two_days_ago) { 2.days.ago }
    let_it_be(:five_days_ago) { 5.days.ago }

    let_it_be(:merge_request) do
      create(:merge_request, :with_merged_metrics, source_project: project, state: :merged, target_branch: "main",
        title: "MR 1", merged_at: two_days_ago)
    end

    let_it_be(:merge_request_two) do
      create(:merge_request, :with_merged_metrics, source_project: project, state: :merged, target_branch: "main",
        title: "MR 2", merged_at: five_days_ago)
    end

    let_it_be(:violation) do
      create(:compliance_violation, :approved_by_committer, severity_level: :high, merge_request: merge_request,
        title: "MR one", target_branch: "master", target_project_id: project_two.id, merged_at: 1.day.ago)
    end

    let_it_be(:violation_two) do
      create(:compliance_violation, :approved_by_committer, severity_level: :high, merge_request: merge_request_two,
        title: "MR 2", target_branch: "main", target_project_id: project.id, merged_at: five_days_ago)
    end

    context 'when inconsistency exists' do
      subject(:compliance_violation_consistency_service) { described_class.new(violation) }

      it 'updates the inconsistent attributes in compliance violations table' do
        expect(violation).not_to have_attributes(expected_attributes(merge_request))

        compliance_violation_consistency_service.execute

        expect(violation.reload).to have_attributes(expected_attributes(merge_request))
        expect(violation.reload.merged_at).to be_within(0.00001.seconds).of(merge_request.merged_at)
      end
    end

    context 'when inconsistency does not exist' do
      subject(:compliance_violation_consistency_service) { described_class.new(violation_two) }

      it 'updates the inconsistent attributes in compliance violations table' do
        expect(violation_two).to have_attributes(expected_attributes(merge_request_two))

        compliance_violation_consistency_service.execute

        expect(violation_two).to have_attributes(expected_attributes(merge_request_two))
        expect(violation_two.reload.merged_at).to be_within(0.00001.seconds).of(merge_request_two.merged_at)
      end
    end
  end

  # @param [MergeRequest, MergeRequests::ComplianceViolation] model
  def expected_attributes(model)
    {
      title: model.title,
      target_branch: model.target_branch,
      target_project_id: model.target_project_id
    }
  end
end
