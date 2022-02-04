# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ComplianceViolation, type: :model do
  let_it_be(:merge_request) { create(:merge_request, state: :merged) }

  describe "Associations" do
    it { is_expected.to belong_to(:violating_user) }
    it { is_expected.to belong_to(:merge_request) }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:violating_user) }
    it { is_expected.to validate_presence_of(:merge_request) }
    it { is_expected.to validate_presence_of(:reason) }
    it { is_expected.to validate_presence_of(:severity_level) }

    context "when a violation exists with the same reason and user for a merge request" do
      let_it_be(:user) { create(:user) }

      before do
        allow(merge_request).to receive(:committers).and_return([user])
        merge_request.approver_users << user
      end

      it "does not create a duplicate merge request violation", :aggregate_failures do
        violation = create(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: user)
        duplicate_violation = build(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: user)

        expect(violation).to be_valid
        expect(duplicate_violation).not_to be_valid
        expect(duplicate_violation.errors.full_messages.join).to eq('Merge request compliance violation has already been recorded')
      end
    end
  end

  describe "Enums" do
    it { is_expected.to define_enum_for(:reason).with_values(::Enums::MergeRequests::ComplianceViolation.reasons) }

    it { is_expected.to define_enum_for(:severity_level).with_values(::Enums::MergeRequests::ComplianceViolation.severity_levels) }
  end

  describe '#approved_by_committer' do
    let_it_be(:violations) do
      [
        create(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: create(:user)),
        create(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: create(:user))
      ]
    end

    before do
      # Add a violation using a different reason to make sure it doesn't pick it up
      create(:compliance_violation, :approved_by_insufficient_users, merge_request: merge_request, violating_user: create(:user))
    end

    it 'returns the correct collection of violations' do
      expect(merge_request.compliance_violations.approved_by_committer).to eq violations
    end
  end

  describe '.process_merge_request' do
    it 'loops through each violation class', :aggregate_failures do
      expect_next_instance_of(::Gitlab::ComplianceManagement::Violations::ApprovedByMergeRequestAuthor, merge_request) do |violation|
        expect(violation).to receive(:execute)
      end

      expect_next_instance_of(::Gitlab::ComplianceManagement::Violations::ApprovedByCommitter, merge_request) do |violation|
        expect(violation).to receive(:execute)
      end

      expect_next_instance_of(::Gitlab::ComplianceManagement::Violations::ApprovedByInsufficientUsers, merge_request) do |violation|
        expect(violation).to receive(:execute)
      end

      described_class.process_merge_request(merge_request)
    end
  end
end
