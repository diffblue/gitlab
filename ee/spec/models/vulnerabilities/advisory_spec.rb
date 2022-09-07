# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Vulnerabilities::Advisory, type: :model do
  using RSpec::Parameterized::TableSyntax

  subject(:advisory) { build(:vulnerability_advisory) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:created_date) }
    it { is_expected.to validate_presence_of(:published_date) }
    it { is_expected.to validate_presence_of(:uuid) }

    describe 'length validation' do
      where(:attribute, :max_length) do
        :title | 2048
        :affected_range | 32
        :not_impacted | 2048
        :solution | 2048
        :cvss_v2 | 128
        :description | 2048
      end

      with_them do
        it { is_expected.to validate_length_of(attribute).is_at_most(max_length) }
      end
    end

    describe 'cvss_v3 validation' do
      it 'validates length of vector' do
        expect_next_instance_of(::Gitlab::Vulnerabilities::Cvss::V3) do |cvss|
          expect(cvss).not_to receive(:valid?)
        end

        advisory.cvss_v3 = Array.new(described_class::VECTOR_MAX_LENGTH + 1).map { 'x' }.join('')
        advisory.validate

        expect(advisory.errors[:cvss_v3]).to include(
          "vector string may not be longer than #{described_class::VECTOR_MAX_LENGTH} characters")
      end

      it 'delegates validation to CVSS class when vector is present' do
        expect_next_instance_of(::Gitlab::Vulnerabilities::Cvss::V3) do |cvss|
          expect(cvss).to receive(:valid?).and_call_original
        end

        expect(advisory).to be_valid
      end

      context 'when vector is not present' do
        before do
          advisory.cvss_v3 = nil
        end

        it 'does not use CVSS class' do
          expect(::Gitlab::Vulnerabilities::Cvss::V3).not_to receive(:new)
          expect(advisory).to be_valid
        end
      end
    end
  end
end
