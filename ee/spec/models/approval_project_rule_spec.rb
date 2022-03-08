# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalProjectRule do
  subject { create(:approval_project_rule) }

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

  describe 'associations' do
    subject { build_stubbed(:approval_project_rule) }

    it { is_expected.to have_many(:approval_merge_request_rule_sources) }
    it { is_expected.to have_many(:approval_merge_request_rules).through(:approval_merge_request_rule_sources) }
  end

  describe '.regular' do
    it 'returns non-report_approver records' do
      rules = create_list(:approval_project_rule, 2)
      create(:approval_project_rule, :vulnerability_report)

      expect(described_class.regular).to contain_exactly(*rules)
    end
  end

  describe '.regular_or_any_approver scope' do
    it 'returns regular or any-approver rules' do
      any_approver_rule = create(:approval_project_rule, rule_type: :any_approver)
      regular_rule = create(:approval_project_rule)
      create(:approval_project_rule, :vulnerability_report)

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

  describe '.vulnerability_reports scope' do
    subject { described_class.vulnerability_reports }

    context 'with vulnerability reports' do
      before do
        create(:approval_project_rule, :vulnerability_report)
      end

      it { is_expected.to be_present }
    end

    context 'without vulnerability reports' do
      before do
        create(:approval_project_rule)
      end

      it { is_expected.to be_empty }
    end
  end

  describe '#regular?' do
    let(:vulnerability_approver_rule) { build(:approval_project_rule, :vulnerability_report) }

    it 'returns true for regular rules' do
      expect(subject.regular?).to eq(true)
    end

    it 'returns false for report_approver rules' do
      expect(vulnerability_approver_rule.regular?). to eq(false)
    end
  end

  describe '#code_owner?' do
    it 'returns false' do
      expect(subject.code_owner?).to eq(false)
    end
  end

  describe '#report_approver?' do
    let(:vulnerability_approver_rule) { build(:approval_project_rule, :vulnerability_report) }

    it 'returns false for regular rules' do
      expect(subject.report_approver?).to eq(false)
    end

    it 'returns true for report_approver rules' do
      expect(vulnerability_approver_rule.report_approver?). to eq(true)
    end
  end

  describe '#rule_type' do
    it 'returns the regular type for regular rules' do
      expect(build(:approval_project_rule).rule_type).to eq('regular')
    end

    it 'returns the report_approver type for vulnerability report approvers rules' do
      expect(build(:approval_project_rule, :vulnerability_report).rule_type).to eq('report_approver')
    end
  end

  describe "#apply_report_approver_rules_to" do
    let(:project) { merge_request.target_project }
    let(:merge_request) { create(:merge_request) }
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    before do
      subject.users << user
      subject.groups << group
    end

    where(:default_name, :report_type) do
      'Vulnerability-Check'  | :vulnerability
      'License-Check'        | :license_scanning
      'Coverage-Check'       | :code_coverage
      'Scan finding example' | :scan_finding
    end

    context "when there is a project rule for each report type" do
      with_them do
        subject { create(:approval_project_rule, report_type, :requires_approval, project: project, orchestration_policy_idx: 1) }

        let!(:result) { subject.apply_report_approver_rules_to(merge_request) }

        specify { expect(merge_request.reload.approval_rules).to match_array([result]) }
        specify { expect(result.users).to match_array([user]) }
        specify { expect(result.groups).to match_array([group]) }
        specify { expect(result.name).to be(:default_name) }
        specify { expect(result.rule_type).to be(:report_approver) }
        specify { expect(result.report_type).to be(:report_type) }
        specify { expect(result.orchestration_policy_idx).to be 1 }
      end
    end
  end

  describe "validation" do
    let(:project_approval_rule) { create(:approval_project_rule) }
    let(:license_compliance_rule) { create(:approval_project_rule, :license_scanning) }
    let(:vulnerability_check_rule) { create(:approval_project_rule, :vulnerability) }
    let(:coverage_check_rule) { create(:approval_project_rule, :code_coverage) }

    context "when creating a new rule" do
      specify { expect(project_approval_rule).to be_valid }
      specify { expect(license_compliance_rule).to be_valid }
      specify { expect(vulnerability_check_rule).to be_valid }
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

      context "with a `Vulnerability-Check` rule" do
        context 'different combinations of specific attributes' do
          using RSpec::Parameterized::TableSyntax

          where(:is_valid, :scanners, :vulnerabilities_allowed, :severity_levels, :vulnerability_states) do
            true  | []                                     | 0     | []                       | %w(newly_detected)
            true  | %w(dast)                               | 1     | %w(critical high medium) | %w(newly_detected resolved)
            true  | %w(dast sast)                          | 10    | %w(critical high)        | %w(resolved detected)
            true  | %w(dast dast)                          | 100   | %w(critical)             | %w(detected dismissed)
            false | %w(dast dast)                          | 100   | %w(critical)             | %w(dismissed unknown)
            false | %w(dast dast)                          | 100   | %w(unknown_severity)     | %w(detected dismissed)
            false | %w(dast unknown_scanner)               | 100   | %w(critical)             | %w(detected dismissed)
            false | [described_class::UNSUPPORTED_SCANNER] | 100   | %w(critical)             | %w(detected dismissed)
            false | %w(dast sast)                          | 1.1   | %w(critical)             | %w(detected dismissed)
            false | %w(dast sast)                          | 'one' | %w(critical)             | %w(detected dismissed)
          end

          with_them do
            let(:vulnerability_check_rule) { build(:approval_project_rule, :vulnerability, scanners: scanners, vulnerabilities_allowed: vulnerabilities_allowed, severity_levels: severity_levels, vulnerability_states: vulnerability_states) }

            specify { expect(vulnerability_check_rule.valid?).to be(is_valid) }
          end
        end

        context 'with invalid name' do
          subject { vulnerability_check_rule }

          specify { expect(subject).not_to be_valid }
          specify { expect { subject.valid? }.to change { subject.errors[:report_type].present? } }
        end
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

    shared_examples 'auditable' do
      context 'when audit event queue is active' do
        before do
          allow(::Gitlab::Audit::EventQueue).to receive(:active?).and_return(true)
        end

        it 'adds message to audit event queue' do
          action!

          expect(::Gitlab::Audit::EventQueue.current).to contain_exactly(message)
        end
      end

      context 'when audit event queue is not active' do
        before do
          allow(::Gitlab::Audit::EventQueue).to receive(:active?).and_return(false)
        end

        it 'does not add message to audit event queue' do
          action!

          expect(::Gitlab::Audit::EventQueue.current).to be_empty
        end
      end
    end

    describe '#audit_add users after :add' do
      let(:action!) { rule.update!(users: [user, new_user]) }
      let(:message) { 'Added User Spiderman to approval group on Vulnerability rule' }

      it_behaves_like 'auditable'
    end

    describe '#audit_remove users after :remove' do
      let(:action!) { rule.update!(users: []) }
      let(:message) { 'Removed User Batman from approval group on Vulnerability rule' }

      it_behaves_like 'auditable'
    end

    describe '#audit_add groups after :add' do
      let(:action!) { rule.update!(groups: [group, new_group]) }
      let(:message) { 'Added Group Avengers to approval group on Vulnerability rule' }

      it_behaves_like 'auditable'
    end

    describe '#audit_remove groups after :remove' do
      let(:action!) { rule.update!(groups: []) }
      let(:message) { 'Removed Group Justice League from approval group on Vulnerability rule' }

      it_behaves_like 'auditable'
    end

    describe "#audit_creation after approval rule is created" do
      let(:action!) { create(:approval_project_rule, approvals_required: 1) }
      let(:message) {'Added approval rule with number of required approvals of 1'}

      it_behaves_like 'auditable'
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

  describe '.distinct_scanners scope' do
    subject { described_class.distinct_scanners }

    before do
      create(:approval_project_rule, type, scanners: ['dast'])
    end

    context 'with scan_finding approval rules' do
      let(:type) { :scan_finding }

      it { is_expected.to be_present }

      context 'with duplicated scanners' do
        before do
          create(:approval_project_rule, :scan_finding, scanners: ['dast'])
        end

        it 'returns only one record' do
          expect(subject.count).to be 1
        end
      end

      context 'without duplicated scanners' do
        before do
          create(:approval_project_rule, :scan_finding, scanners: ['sast'])
        end

        it 'returns both records' do
          expect(subject.count).to be 2
        end
      end
    end

    context 'without scan_finding approval rules' do
      let(:type) { :vulnerability }

      it { is_expected.to be_empty }
    end
  end
end
