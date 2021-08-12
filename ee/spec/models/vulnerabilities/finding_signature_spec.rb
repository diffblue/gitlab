# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::FindingSignature do
  let_it_be(:signature) { create(:vulnerabilities_finding_signature) }

  describe 'associations' do
    it { is_expected.to belong_to(:finding).class_name('Vulnerabilities::Finding').with_foreign_key('finding_id') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:finding) }
  end

  describe '.by_project' do
    let(:project) { create(:project) }
    let(:finding) { create(:vulnerabilities_finding, project: project) }
    let!(:expected_signature) { create(:vulnerabilities_finding_signature, finding: finding) }

    subject { described_class.by_project(project) }

    it { is_expected.to eq([expected_signature]) }
  end

  describe '.by_signature_sha' do
    let(:signature_sha) { ::Digest::SHA1.digest(SecureRandom.hex(50)) }
    let!(:expected_signature) { create(:vulnerabilities_finding_signature, signature_sha: signature_sha) }

    subject { described_class.by_signature_sha(signature_sha) }

    it { is_expected.to eq([expected_signature]) }
  end
end
