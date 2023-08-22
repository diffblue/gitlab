# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Approvals::WrappedRuleSet do
  let(:report_type) { nil }
  let(:merge_request) { build(:merge_request) }
  let(:approval_merge_request_rule) { build(:approval_merge_request_rule, merge_request: merge_request, report_type: report_type) }
  let(:approval_rules) { [approval_merge_request_rule] }
  let(:grouped_approval_wrapped_rules) { described_class.wrap(merge_request, approval_rules, report_type) }

  describe '.wrap' do
    subject { grouped_approval_wrapped_rules }

    context "with report_type set to #{Security::ScanResultPolicy::SCAN_FINDING}" do
      let(:report_type) { Security::ScanResultPolicy::SCAN_FINDING }

      it { is_expected.to be_instance_of(Approvals::ScanFindingWrappedRuleSet) }
    end

    context 'with any other report_type' do
      it { is_expected.to be_instance_of(described_class) }
    end

    context 'with scan_finding and license_scanning together' do
      let(:report_type) { Security::ScanResultPolicy::SCAN_FINDING }

      let(:license_scanning_rule) do
        build(:approval_merge_request_rule,
          merge_request: merge_request,
          report_type: Security::ScanResultPolicy::LICENSE_SCANNING
        )
      end

      let(:approval_rules) { [approval_merge_request_rule, license_scanning_rule] }

      it { is_expected.to be_instance_of(Approvals::ScanFindingWrappedRuleSet) }
    end
  end

  describe '#wrapped_rules' do
    subject { grouped_approval_wrapped_rules.wrapped_rules }

    it 'returns an array of ApprovalWrappedRule' do
      expect(subject.count).to be 1
      expect(subject.first).to be_instance_of(ApprovalWrappedRule)
    end

    it "returns ApprovalWrappedRule with attributes as provided to #{described_class.name}" do
      expect(subject.first).to have_attributes(merge_request: merge_request, approval_rule: approval_merge_request_rule)
    end
  end
end
