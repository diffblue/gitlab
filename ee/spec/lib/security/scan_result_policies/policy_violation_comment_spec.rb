# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::PolicyViolationComment, feature_category: :security_policy_management do
  using RSpec::Parameterized::TableSyntax

  let(:comment) { described_class.new(existing_comment) }

  def build_comment(reports: [], optional_approvals: [])
    build(:note,
      author: build(:user, :security_bot),
      note: [
        described_class::MESSAGE_HEADER,
        "<!-- violated_reports: #{reports.join(',')} -->",
        "<!-- optional_approvals: #{optional_approvals.join(',')} -->",
        "Comment body"
      ].join("\n"))
  end

  describe '#reports' do
    subject(:execute) { comment.reports }

    where(:existing_comment, :expected) do
      nil | []
      build_comment(reports: %w[scan_finding]) | %w[scan_finding]
      build_comment(reports: %w[scan_finding license_scanning]) | %w[scan_finding license_scanning]
      build_comment(reports: %w[scan_finding invalid]) | %w[scan_finding]
      build(:note, note: "invalid format") | []
    end

    with_them do
      it { is_expected.to match_array(expected) }
    end
  end

  describe '#optional_approval_reports' do
    subject(:execute) { comment.optional_approval_reports }

    where(:existing_comment, :expected) do
      nil | []
      build_comment(optional_approvals: %w[scan_finding]) | %w[scan_finding]
      build_comment(optional_approvals: %w[scan_finding license_scanning]) | %w[scan_finding license_scanning]
      build_comment(optional_approvals: %w[scan_finding invalid]) | %w[scan_finding]
      build(:note, note: "invalid format") | []
    end

    with_them do
      it { is_expected.to match_array(expected) }
    end
  end

  describe '#add_report_type' do
    subject(:add_report_type) { comment.add_report_type(report_type, requires_approval) }

    where(:report_type, :requires_approval, :existing_comment, :expected_reports, :expected_optional_reports) do
      'scan_finding' | true | nil | %w[scan_finding] | []
      'scan_finding' | false | nil | %w[scan_finding] | %w[scan_finding]
      'scan_finding' | true | build_comment(reports: %w[scan_finding]) | %w[scan_finding] | []
      'scan_finding' | false | build_comment(reports: %w[scan_finding]) | %w[scan_finding] | %w[scan_finding]
      'scan_finding' | true | build_comment(reports: %w[license_scanning]) | %w[scan_finding license_scanning] | []
      'scan_finding' | false | build_comment(reports: %w[license_scanning]) | %w[scan_finding
        license_scanning] | %w[scan_finding]
      'scan_finding' | false | build_comment(optional_approvals: %w[license_scanning]) | %w[scan_finding] | %w[
        license_scanning scan_finding
      ]
      'invalid' | true | build_comment(reports: %w[license_scanning]) | %w[license_scanning] | []
      'invalid' | false | build_comment(reports: %w[license_scanning],
        optional_approvals: %w[license_scanning]) | %w[license_scanning] | %w[license_scanning]
    end

    before do
      add_report_type
    end

    with_them do
      it { expect(comment.reports).to match_array(expected_reports) }
      it { expect(comment.optional_approval_reports).to match_array(expected_optional_reports) }
    end
  end

  describe '#remove_report_type' do
    subject(:remove_report_type) { comment.remove_report_type(report_type) }

    where(:report_type, :existing_comment, :expected_reports, :expected_optional_reports) do
      'scan_finding' | nil | [] | []
      'scan_finding' | build_comment(reports: %w[scan_finding]) | [] | []
      'scan_finding' | build_comment(reports: %w[scan_finding], optional_approvals: %w[scan_finding]) | [] | []
      'scan_finding' | build_comment(reports: %w[license_scanning]) | %w[license_scanning] | []
      'scan_finding' | build_comment(reports: %w[license_scanning],
        optional_approvals: %w[license_scanning]) | %w[license_scanning] | %w[license_scanning]
    end

    before do
      remove_report_type
    end

    with_them do
      it { expect(comment.reports).to match_array(expected_reports) }
      it { expect(comment.optional_approval_reports).to match_array(expected_optional_reports) }
    end
  end

  describe '#body' do
    subject { comment.body }

    let_it_be(:violations_resolved) { 'Security policy violations have been resolved.' }
    let_it_be(:violations_detected) { 'Policy violation(s) detected' }
    let_it_be(:optional_approvals_detected) { 'Consider including optional reviewers' }

    context 'when there is no existing comment and no reports' do
      let(:existing_comment) { nil }

      it { is_expected.to be_nil }
    end

    where(:report_type_to_add, :requires_approval, :report_type_to_remove, :existing_comment, :expected_body) do
      'scan_finding' | true | nil | nil | ref(:violations_detected)
      'scan_finding' | false | nil | nil | ref(:optional_approvals_detected)
      'scan_finding' | true | nil | build_comment(reports: %w[license_scanning]) | ref(:violations_detected)
      'scan_finding' | false | nil | build_comment(reports: %w[license_scanning]) | ref(:violations_detected)
      'scan_finding' | false | nil | build_comment(reports: %w[scan_finding]) | ref(:optional_approvals_detected)
      nil | nil | 'scan_finding' | build_comment(reports: %w[license_scanning]) | ref(:violations_detected)
      nil | nil | 'license_scanning' | build_comment(reports: %w[license_scanning]) | ref(:violations_resolved)
      nil | nil | 'scan_finding' | build_comment(reports: %w[scan_finding],
        optional_approvals: %w[scan_finding]) | ref(:violations_resolved)
    end

    with_them do
      before do
        comment.add_report_type(report_type_to_add, requires_approval) if report_type_to_add
        comment.remove_report_type(report_type_to_remove) if report_type_to_remove
      end

      it { is_expected.to start_with(described_class::MESSAGE_HEADER) }
      it { is_expected.to include(expected_body) }
    end
  end
end
