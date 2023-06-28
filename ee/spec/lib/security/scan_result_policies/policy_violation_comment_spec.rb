# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::PolicyViolationComment, feature_category: :security_policy_management do
  using RSpec::Parameterized::TableSyntax

  let(:comment) { described_class.new(existing_comment) }

  def build_comment(reports:)
    build(:note,
      author: build(:user, :security_bot),
      note: [
        described_class::MESSAGE_HEADER,
        "<!-- violated_reports: #{reports.join(',')} -->",
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

  describe '#add_report_type' do
    subject { comment.add_report_type(report_type) }

    where(:report_type, :existing_comment, :expected) do
      'scan_finding' | nil | %w[scan_finding]
      'scan_finding' | build_comment(reports: %w[scan_finding]) | %w[scan_finding]
      'scan_finding' | build_comment(reports: %w[license_scanning]) | %w[scan_finding license_scanning]
      'invalid' | build_comment(reports: %w[license_scanning]) | %w[license_scanning]
    end

    with_them do
      it { is_expected.to match_array(expected) }
    end
  end

  describe '#remove_report_type' do
    subject { comment.remove_report_type(report_type) }

    where(:report_type, :existing_comment, :expected) do
      'scan_finding' | nil | []
      'scan_finding' | build_comment(reports: %w[scan_finding]) | []
      'scan_finding' | build_comment(reports: %w[license_scanning]) | %w[license_scanning]
    end

    with_them do
      it { is_expected.to match_array(expected) }
    end
  end

  describe '#body' do
    subject { comment.body }

    let_it_be(:violations_resolved) { 'Security policy violations have been resolved.' }
    let_it_be(:violations_detected) { 'Policy violation(s) detected' }

    context 'when there is no existing comment and no reports' do
      let(:existing_comment) { nil }

      it { is_expected.to be_nil }
    end

    where(:report_type_to_add, :report_type_to_remove, :existing_comment, :expected_body) do
      'scan_finding' | nil | nil | ref(:violations_detected)
      'scan_finding' | nil | build_comment(reports: %w[license_scanning]) | ref(:violations_detected)
      nil | 'scan_finding' | build_comment(reports: %w[license_scanning]) | ref(:violations_detected)
      nil | 'license_scanning' | build_comment(reports: %w[license_scanning]) | ref(:violations_resolved)
    end

    with_them do
      before do
        comment.add_report_type(report_type_to_add) if report_type_to_add
        comment.remove_report_type(report_type_to_remove) if report_type_to_remove
      end

      it { is_expected.to start_with(described_class::MESSAGE_HEADER) }
      it { is_expected.to include(expected_body) }
    end
  end
end
