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

    ApprovalProjectRule::REPORT_TYPES_BY_DEFAULT_NAME.each do |name, value|
      context "when the project rule is for a `#{name}`" do
        subject { create(:approval_project_rule, value, :requires_approval, project: project) }

        let!(:result) { subject.apply_report_approver_rules_to(merge_request) }

        specify { expect(merge_request.reload.approval_rules).to match_array([result]) }
        specify { expect(result.users).to match_array([user]) }
        specify { expect(result.groups).to match_array([group]) }
      end
    end
  end

  describe "validation" do
    let(:project_approval_rule) { create(:approval_project_rule) }
    let(:license_compliance_rule) { create(:approval_project_rule, :license_scanning) }
    let(:vulnerability_check_rule) { create(:approval_project_rule, :vulnerability) }

    context "when creating a new rule" do
      specify { expect(project_approval_rule).to be_valid }
      specify { expect(license_compliance_rule).to be_valid }
      specify { expect(vulnerability_check_rule).to be_valid }
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
        specify { expect { subject.valid? }.to change { subject.errors[:name].present? } }
      end

      context "with a `Vulnerability-Check` rule" do
        using RSpec::Parameterized::TableSyntax

        where(:is_valid, :scanners, :vulnerabilities_allowed, :severity_levels) do
          true  | []                                     | 0     | []
          true  | %w(dast)                               | 1     | %w(critical high medium)
          true  | %w(dast sast)                          | 10    | %w(critical high)
          true  | %w(dast dast)                          | 100   | %w(critical)
          false | %w(dast dast)                          | 100   | %w(unknown_severity)
          false | %w(dast unknown_scanner)               | 100   | %w(critical)
          false | [described_class::UNSUPPORTED_SCANNER] | 100   | %w(critical)
          false | %w(dast sast)                          | 1.1   | %w(critical)
          false | %w(dast sast)                          | 'one' | %w(critical)
        end

        with_them do
          let(:vulnerability_check_rule) { build(:approval_project_rule, :vulnerability, scanners: scanners, vulnerabilities_allowed: vulnerabilities_allowed, severity_levels: severity_levels) }

          specify { expect(vulnerability_check_rule.valid?).to be(is_valid) }
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
      expect { rule.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
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
      let(:action!) { rule.update(users: [user, new_user]) }
      let(:message) { 'Added User Spiderman to approval group on Vulnerability rule' }

      it_behaves_like 'auditable'
    end

    describe '#audit_remove users after :remove' do
      let(:action!) { rule.update(users: []) }
      let(:message) { 'Removed User Batman from approval group on Vulnerability rule' }

      it_behaves_like 'auditable'
    end

    describe '#audit_add groups after :add' do
      let(:action!) { rule.update(groups: [group, new_group]) }
      let(:message) { 'Added Group Avengers to approval group on Vulnerability rule' }

      it_behaves_like 'auditable'
    end

    describe '#audit_remove groups after :remove' do
      let(:action!) { rule.update(groups: []) }
      let(:message) { 'Removed Group Justice League from approval group on Vulnerability rule' }

      it_behaves_like 'auditable'
    end
  end
end
