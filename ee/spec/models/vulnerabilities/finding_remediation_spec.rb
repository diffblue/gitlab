# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::FindingRemediation, feature_category: :vulnerability_management do
  it { is_expected.to belong_to(:finding).class_name('Vulnerabilities::Finding').required }
  it { is_expected.to belong_to(:remediation).class_name('Vulnerabilities::Remediation').required }

  describe '.by_finding_id' do
    let(:finding_1) { create(:vulnerabilities_finding) }
    let!(:remediation) { create(:vulnerabilities_remediation, findings: [finding_1]) }

    subject { described_class.by_finding_id(finding_1.id) }

    it { is_expected.to eq(remediation.finding_remediations) }
  end
end
