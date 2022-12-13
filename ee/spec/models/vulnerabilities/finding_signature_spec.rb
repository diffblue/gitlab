# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::FindingSignature, feature_category: :vulnerability_management do
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

  describe '#eql?' do
    context 'when the other is also a FindingSignature' do
      context 'when algorithm_type and signature_sha are the same' do
        let(:other) do
          build(
            :vulnerabilities_finding_signature,
            signature_sha: signature.signature_sha,
            algorithm_type: signature.algorithm_type)
        end

        it 'returns true' do
          expect(signature.eql?(other)).to eq(true)
        end
      end

      context 'when algorithm_type is different' do
        let(:other) { build(:vulnerabilities_finding_signature, :location) }

        it 'returns false' do
          expect(signature.eql?(other)).to eq(false)
        end
      end

      context 'when signature_sha is different' do
        let(:other) { build(:vulnerabilities_finding_signature) }

        before do
          other.signature_sha = other.signature_sha.reverse
        end

        it 'returns false' do
          expect(signature.eql?(other)).to eq(false)
        end
      end
    end

    context 'when the other is not a FindingSignature' do
      it 'returns false' do
        expect(signature.eql?('something else')).to eq(false)
      end
    end
  end
end
