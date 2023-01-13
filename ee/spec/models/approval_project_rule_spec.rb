# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalProjectRule do
  subject(:rule) { create(:approval_project_rule) }

  describe 'validations' do
    it 'is invalid when name not unique within rule type and project' do
      is_expected.to validate_uniqueness_of(:name).scoped_to([:project_id, :rule_type])
    end

    context 'DEFAULT_SEVERITIES' do
      it 'contains a valid subset of severity levels' do
        expect(::Enums::Vulnerability.severity_levels.keys).to include(*described_class::DEFAULT_SEVERITIES)
      end
    end

    context 'APPROVAL_VULNERABILITY_STATES' do
      it 'contains all vulnerability states' do
        expect(described_class::APPROVAL_VULNERABILITY_STATES).to include(*::Enums::Vulnerability.vulnerability_states.keys)
      end
    end
  end

  describe 'default values' do
    subject(:rule) { described_class.new }

    it { expect(rule.scanners).to eq([]) }
    it { expect(rule.vulnerabilities_allowed).to eq(0) }
  end

  describe 'scanners' do
    it 'transform existing NULL values into empty array' do
      rule.update_column(:scanners, nil)

      expect(rule.reload.scanners).to eq([])
    end

    it 'prevents assignment of NULL' do
      rule.scanners = nil

      expect(rule.scanners).to eq([])
    end

    it 'prevents assignment of NULL via assign_attributes' do
      rule.assign_attributes(scanners: nil)

      expect(rule.scanners).to eq([])
    end
  end

  describe 'associations' do
    subject { build_stubbed(:approval_project_rule) }

    it { is_expected.to have_many(:approval_merge_request_rule_sources) }
    it { is_expected.to have_many(:approval_merge_request_rules).through(:approval_merge_request_rule_sources) }
  end

  describe '.regular' do
    it 'returns non-report_approver records' do
      rules = create_list(:approval_project_rule, 2)
      create(:approval_project_rule, :license_scanning)

      expect(described_class.regular).to contain_exactly(*rules)
    end
  end

  describe '.regular_or_any_approver scope' do
    it 'returns regular or any-approver rules' do
      any_approver_rule = create(:approval_project_rule, rule_type: :any_approver)
      regular_rule = create(:approval_project_rule)
      create(:approval_project_rule, :license_scanning)

      expect(described_class.regular_or_any_approver).to(
        contain_exactly(any_approver_rule, regular_rule)
      )
    end
  end

  describe '.code_owner scope' do
    it 'returns nothing' do
      create_list(:approval_project_rule, 2)

      expect(described_class.code_owner).to be_empty
    end
  end

  describe '#protected_branches' do
    let_it_be(:project) { create(:project) }
    let_it_be(:rule_protected_branch) { create(:protected_branch) }
    let_it_be(:rule) { create(:approval_project_rule, protected_branches: [rule_protected_branch], project: project) }
    let_it_be(:protected_branches) { create_list(:protected_branch, 3, project: project) }

    subject { rule.protected_branches }

    context 'when applies_to_all_protected_branches is true' do
      before do
        rule.update!(applies_to_all_protected_branches: true)
      end

      it 'returns a collection of all protected branches belonging to the project' do
        expect(subject).to contain_exactly(*protected_branches)
      end
    end

    context 'when applies_to_all_protected_branches is false' do
      before do
        rule.update!(applies_to_all_protected_branches: false)
      end

      it 'returns a collection of all protected branches belonging to the rule' do
        expect(subject).to contain_exactly(rule_protected_branch)
      end
    end
  end

  describe '#applies_to_branch?' do
    let_it_be(:protected_branch) { create(:protected_branch) }

    context 'when rule has no specific branches' do
      it 'returns true' do
        expect(subject.applies_to_branch?('branch_name')).to be true
      end
    end

    context 'when rule has specific branches' do
      before do
        rule.protected_branches << protected_branch
      end

      it 'returns true when the branch name matches' do
        expect(rule.applies_to_branch?(protected_branch.name)).to be true
      end

      it 'returns false when the branch name does not match' do
        expect(rule.applies_to_branch?('random-branch-name')).to be false
      end
    end

    context 'when rule applies to all protected branches' do
      let_it_be(:wildcard_protected_branch) { create(:protected_branch, name: "stable-*") }

      let(:project) { rule.project }

      before do
        rule.update!(applies_to_all_protected_branches: true)
        project.protected_branches << protected_branch
        project.protected_branches << wildcard_protected_branch
      end

      it 'returns true when the branch name is a protected branch' do
        expect(rule.reload.applies_to_branch?(protected_branch.name)).to be true
      end

      it 'returns true when the branch name is a wildcard protected branch' do
        expect(rule.reload.applies_to_branch?('stable-12')).to be true
      end

      it 'returns false when the branch name does not match a wildcard protected branch' do
        expect(rule.reload.applies_to_branch?('unstable1-12')).to be false
      end

      it 'returns false when the branch name is an unprotected branch' do
        expect(rule.applies_to_branch?('add-balsamiq-file')).to be false
      end

      it 'returns false when the branch name does not exist' do
        expect(rule.applies_to_branch?('this-is-not-a-real-branch')).to be false
      end
    end
  end

  describe '#regular?' do
    let(:license_scanning_approver_rule) { build(:approval_project_rule, :license_scanning) }

    it 'returns true for regular rules' do
      expect(subject.regular?).to eq(true)
    end

    it 'returns false for report_approver rules' do
      expect(license_scanning_approver_rule.regular?).to eq(false)
    end
  end

  describe '#code_owner?' do
    it 'returns false' do
      expect(subject.code_owner?).to eq(false)
    end
  end

  describe '#report_approver?' do
    let(:license_scanning_approver_rule) { build(:approval_project_rule, :license_scanning) }

    it 'returns false for regular rules' do
      expect(subject.report_approver?).to eq(false)
    end

    it 'returns true for report_approver rules' do
      expect(license_scanning_approver_rule.report_approver?).to eq(true)
    end
  end

  describe '#rule_type' do
    it 'returns the regular type for regular rules' do
      expect(build(:approval_project_rule).rule_type).to eq('regular')
    end

    it 'returns the report_approver type for license scanning approvers rules' do
      expect(build(:approval_project_rule, :license_scanning).rule_type).to eq('report_approver')
    end
  end

  describe "#apply_report_approver_rules_to" do
    let(:project) { merge_request.target_project }
    let(:merge_request) { create(:merge_request) }
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :project) }

    before do
      subject.users << user
      subject.groups << group
    end

    where(:default_name, :report_type) do
      'License-Check'        | :license_scanning
      'Coverage-Check'       | :code_coverage
      'Scan finding example' | :scan_finding
    end

    context "when there is a project rule for each report type" do
      with_them do
        subject { create(:approval_project_rule, report_type, :requires_approval, project: project, orchestration_policy_idx: 1, scanners: [:sast], severity_levels: [:high], vulnerability_states: [:confirmed], vulnerabilities_allowed: 2, security_orchestration_policy_configuration: security_orchestration_policy_configuration) }

        let!(:result) { subject.apply_report_approver_rules_to(merge_request) }

        specify { expect(merge_request.reload.approval_rules).to match_array([result]) }
        specify { expect(result.users).to match_array([user]) }
        specify { expect(result.groups).to match_array([group]) }
        specify { expect(result.name).to be(:default_name) }
        specify { expect(result.rule_type).to be(:report_approver) }
        specify { expect(result.report_type).to be(:report_type) }
        specify { expect(result.orchestration_policy_idx).to be 1 }
        specify { expect(result.scanners).to be match_array([:sast]) }
        specify { expect(result.severity_levels).to be match_array([:high]) }
        specify { expect(result.vulnerability_states).to match_array([:confirmed]) }
        specify { expect(result.vulnerabilities_allowed).to be 2 }
        specify { expect(result.security_orchestration_policy_configuration.id).to be security_orchestration_policy_configuration.id }
      end
    end
  end

  describe "validation" do
    let(:project_approval_rule) { create(:approval_project_rule) }
    let(:license_compliance_rule) { create(:approval_project_rule, :license_scanning) }
    let(:coverage_check_rule) { create(:approval_project_rule, :code_coverage) }

    context "when creating a new rule" do
      specify { expect(project_approval_rule).to be_valid }
      specify { expect(license_compliance_rule).to be_valid }
      specify { expect(coverage_check_rule).to be_valid }
    end

    context "when attempting to edit the name of the rule" do
      subject { project_approval_rule }

      before do
        subject.name = SecureRandom.uuid
      end

      specify { expect(subject).to be_valid }

      context "with a `License-Check` rule" do
        subject { license_compliance_rule }

        specify { expect(subject).not_to be_valid }
        specify { expect { subject.valid? }.to change { subject.errors[:report_type].present? } }
      end

      context "with a `Coverage-Check` rule" do
        subject { coverage_check_rule }

        specify { expect(subject).not_to be_valid }
        specify { expect { subject.valid? }.to change { subject.errors[:report_type].present? } }
      end
    end

    context 'for report type different than scan_finding' do
      it 'is invalid when name not unique within rule type and project' do
        is_expected.to validate_uniqueness_of(:name).scoped_to([:project_id, :rule_type])
      end
    end

    context 'for scan_finding report type' do
      subject { create(:approval_project_rule, :scan_finding) }

      it 'is invalid when name not unique within scan result policy, rule type and project' do
        is_expected.to validate_uniqueness_of(:name).scoped_to([:project_id, :rule_type, :security_orchestration_policy_configuration_id, :orchestration_policy_idx])
      end
    end
  end

  context 'any_approver rules' do
    let(:project) { create(:project) }
    let(:rule) { build(:approval_project_rule, project: project, rule_type: :any_approver) }

    it 'creating only one any_approver rule is allowed' do
      create(:approval_project_rule, project: project, rule_type: :any_approver)

      expect(rule).not_to be_valid
      expect(rule.errors.messages).to eq(rule_type: ['any-approver for the project already exists'])
      expect { rule.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'callbacks', :request_store do
    let_it_be(:user) { create(:user, name: 'Batman') }
    let_it_be(:group) { create(:group, name: 'Justice League') }

    let_it_be(:new_user) { create(:user, name: 'Spiderman') }
    let_it_be(:new_group) { create(:group, name: 'Avengers') }

    let_it_be(:rule, reload: true) { create(:approval_project_rule, name: 'Vulnerability', users: [user], groups: [group]) }

    describe '#track_creation_event tracks count after create' do
      let_it_be(:approval_project_rule) { build(:approval_project_rule) }

      it 'calls Gitlab::UsageDataCounters::HLLRedisCounter track event' do
        allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)

        approval_project_rule.save!

        expect(Gitlab::UsageDataCounters::HLLRedisCounter).to have_received(:track_event)
                                                                .with('approval_project_rule_created', values: approval_project_rule.id)
      end
    end

    describe '#audit_add users after :add' do
      let(:action!) { rule.update!(users: [user, new_user]) }
      let(:message) { 'Added User Spiderman to approval group on Vulnerability rule' }

      it_behaves_like 'audit event queue'
    end

    describe '#audit_remove users after :remove' do
      let(:action!) { rule.update!(users: []) }
      let(:message) { 'Removed User Batman from approval group on Vulnerability rule' }

      it_behaves_like 'audit event queue'
    end

    describe '#audit_add groups after :add' do
      let(:action!) { rule.update!(groups: [group, new_group]) }
      let(:message) { 'Added Group Avengers to approval group on Vulnerability rule' }

      it_behaves_like 'audit event queue'
    end

    describe '#audit_remove groups after :remove' do
      let(:action!) { rule.update!(groups: []) }
      let(:message) { 'Removed Group Justice League from approval group on Vulnerability rule' }

      it_behaves_like 'audit event queue'
    end

    describe "#audit_creation after approval rule is created" do
      let(:action!) { create(:approval_project_rule, approvals_required: 1) }
      let(:message) { 'Added approval rule with number of required approvals of 1' }

      it_behaves_like 'audit event queue'
    end

    describe '#vulnerability_states_for_branch' do
      let(:project) { create(:project, :repository) }
      let(:branch_name) { project.default_branch }
      let!(:rule) { build(:approval_project_rule, project: project, protected_branches: protected_branches, vulnerability_states: %w(newly_detected resolved)) }

      context 'with protected branch set to any' do
        let(:protected_branches) { [] }

        it 'returns all content of vulnerability states' do
          expect(rule.vulnerability_states_for_branch).to contain_exactly('newly_detected', 'resolved')
        end
      end

      context 'with protected branch set to a custom branch' do
        let(:protected_branches) { [create(:protected_branch, project: project, name: 'custom_branch')] }

        it 'returns only the content of vulnerability states' do
          expect(rule.vulnerability_states_for_branch).to contain_exactly('newly_detected')
        end
      end
    end
  end
end
