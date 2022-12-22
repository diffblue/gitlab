# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Remediation, feature_category: :vulnerability_management do
  it { is_expected.to belong_to(:project).required }
  it { is_expected.to have_many(:finding_remediations).class_name('Vulnerabilities::FindingRemediation') }
  it { is_expected.to have_many(:findings).through(:finding_remediations) }

  it { is_expected.to validate_presence_of(:summary) }
  it { is_expected.to validate_presence_of(:file) }
  it { is_expected.to validate_presence_of(:checksum) }
  it { is_expected.to validate_length_of(:summary).is_at_most(200) }

  describe '.by_checksum' do
    let_it_be(:remediation_1) { create(:vulnerabilities_remediation) }
    let_it_be(:remediation_2) { create(:vulnerabilities_remediation) }

    subject { described_class.by_checksum(remediation_2.checksum) }

    it { is_expected.to match_array([remediation_2]) }
  end

  describe '#diff' do
    let(:diff_content) { 'foo' }
    let(:diff_file) { Tempfile.new.tap { |f| f.write(diff_content) } }
    let(:remediation) { create(:vulnerabilities_remediation, file: diff_file) }

    subject { remediation.diff }

    it { is_expected.to eq(diff_content) }
  end
end
