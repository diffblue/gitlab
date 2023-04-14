# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ComplianceViolation, type: :model, feature_category: :compliance_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:merge_request) { create(:merge_request, state: :merged, title: 'zyxw') }
  let_it_be(:user) { create(:user) }

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

  describe '#by_approved_by_committer' do
    let_it_be(:violations) do
      [
        create(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: user),
        create(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: create(:user))
      ]
    end

    before do
      # Add a violation using a different reason to make sure it doesn't pick it up
      create(:compliance_violation, :approved_by_insufficient_users, merge_request: merge_request, violating_user: user)
    end

    it 'returns the correct collection of violations' do
      expect(merge_request.compliance_violations.by_approved_by_committer).to eq violations
    end
  end

  describe '#by_group' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, :repository, group: group) }
    let_it_be(:subgroup_project) { create(:project, :repository, group: subgroup) }
    let_it_be(:alt_merge_request) { create(:merge_request, source_project: project, target_project: project, state: :merged) }
    let_it_be(:subgroup_merge_request) { create(:merge_request, source_project: subgroup_project, target_project: project, state: :merged) }
    let_it_be(:violations) do
      [
        create(:compliance_violation, :approved_by_committer, merge_request: alt_merge_request, violating_user: user),
        create(:compliance_violation, :approved_by_committer, merge_request: subgroup_merge_request, violating_user: user),
        create(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: user)
      ]
    end

    it 'returns the correct collection of violations' do
      expect(described_class.by_group(group)).to contain_exactly(violations[0], violations[1])
    end
  end

  describe '#by_projects' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:alt_merge_request) { create(:merge_request, source_project: project, target_project: project, state: :merged) }
    let_it_be(:violations) do
      [
        create(:compliance_violation, :approved_by_committer, merge_request: alt_merge_request, violating_user: create(:user)),
        create(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: create(:user))
      ]
    end

    it 'returns the correct collection of violations' do
      expect(described_class.by_projects([project.id])).to contain_exactly(violations[0])
    end
  end

  describe '#merged_before' do
    let_it_be(:alt_merge_request) { create(:merge_request, state: :merged) }
    let_it_be(:violations) do
      [
        create(:compliance_violation, :approved_by_committer, merge_request: alt_merge_request, violating_user: create(:user), merged_at: 2.days.ago),
        create(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: create(:user))
      ]
    end

    it 'returns the correct collection of violations' do
      expect(described_class.merged_before(2.days.ago)).to contain_exactly(violations[0])
    end
  end

  describe '#merged_after' do
    let_it_be(:alt_merge_request) { create(:merge_request, state: :merged) }
    let_it_be(:violations) do
      [
        create(:compliance_violation, :approved_by_committer, merge_request: alt_merge_request, violating_user: create(:user), merged_at: Date.current),
        create(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: create(:user))
      ]
    end

    it 'returns the correct collection of violations' do
      expect(described_class.merged_after(Date.current)).to contain_exactly(violations[0])
    end
  end

  describe '#order_by_reason' do
    let_it_be(:violations) do
      [
        create(:compliance_violation, :approved_by_merge_request_author, merge_request: merge_request, violating_user: create(:user)),
        create(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: create(:user))
      ]
    end

    where(:direction, :result) do
      'ASC'  | lazy { [violations[0], violations[1]] }
      'DESC' | lazy { [violations[1], violations[0]] }
    end

    with_them do
      it 'returns the correct collection of violations' do
        expect(described_class.order_by_reason(direction)).to match_array(result)
      end
    end
  end

  describe '#order_by_severity_level' do
    let_it_be(:violations) do
      [
        create(:compliance_violation, :approved_by_committer, severity_level: :low, merge_request: merge_request, violating_user: create(:user)),
        create(:compliance_violation, :approved_by_committer, severity_level: :high, merge_request: merge_request, violating_user: create(:user))
      ]
    end

    where(:direction, :result) do
      'ASC'  | lazy { [violations[0], violations[1]] }
      'DESC' | lazy { [violations[1], violations[0]] }
    end

    with_them do
      it 'returns the correct collection of violations' do
        expect(described_class.order_by_severity_level(direction)).to match_array(result)
      end
    end
  end

  describe '#order_by_merge_request_title' do
    let_it_be(:alt_merge_request) { create(:merge_request, state: :merged, title: 'abcd') }
    let_it_be(:violations) do
      [
        create(:compliance_violation, :approved_by_committer, severity_level: :high, merge_request: alt_merge_request, violating_user: create(:user)),
        create(:compliance_violation, :approved_by_committer, severity_level: :low, merge_request: merge_request, violating_user: create(:user))
      ]
    end

    where(:direction, :result) do
      'ASC'  | lazy { [violations[0], violations[1]] }
      'DESC' | lazy { [violations[1], violations[0]] }
    end

    with_them do
      it 'returns the correct collection of violations' do
        expect(described_class.order_by_merge_request_title(direction)).to match_array(result)
      end
    end
  end

  describe '#order_by_merged_at' do
    let_it_be(:alt_merge_request) { create(:merge_request, state: :merged) }
    let_it_be(:violations) do
      [
        create(:compliance_violation, :approved_by_committer, merge_request: alt_merge_request, violating_user: create(:user)),
        create(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: create(:user))
      ]
    end

    before do
      alt_merge_request.metrics.update!(merged_at: 2.days.ago)
    end

    where(:direction, :result) do
      'ASC'  | lazy { [violations[0], violations[1]] }
      'DESC' | lazy { [violations[1], violations[0]] }
    end

    with_them do
      it 'returns the correct collection of violations' do
        expect(described_class.order_by_merged_at(direction)).to match_array(result)
      end
    end
  end

  describe '#by_target_branch' do
    let_it_be(:violations) do
      [
        create(:compliance_violation, :approved_by_committer, merge_request: merge_request, target_branch: 'main', violating_user: create(:user)),
        create(:compliance_violation, :approved_by_merge_request_author, merge_request: merge_request, target_branch: 'master', violating_user: create(:user))
      ]
    end

    it 'returns the correct collection of violations' do
      expect(described_class.by_target_branch('master')).to contain_exactly(violations[1])
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
