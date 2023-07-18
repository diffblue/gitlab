# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Advisory, type: :model, feature_category: :software_composition_analysis do
  using RSpec::Parameterized::TableSyntax

  subject(:advisory) { build(:pm_advisory) }

  describe 'validations' do
    it_behaves_like 'model with cvss v2 vector validation', :cvss_v2
    it_behaves_like 'model with cvss v3 vector validation', :cvss_v3

    it { is_expected.to validate_presence_of(:advisory_xid) }
    it { is_expected.to validate_presence_of(:source_xid) }
    it { is_expected.to validate_presence_of(:published_date) }
    it { is_expected.to allow_value(nil).for(:cvss_v2) }
    it { is_expected.to allow_value(nil).for(:cvss_v3) }
    it { is_expected.not_to allow_value('').for(:cvss_v2) }
    it { is_expected.not_to allow_value('').for(:cvss_v3) }

    describe 'length validation' do
      where(:attribute, :value, :is_valid) do
        :advisory_xid | ('a' * 36)            | true
        :advisory_xid | ('a' * 37)            | false
        :title        | ('a' * 256)           | true
        :title        | ('a' * 257)           | false
        :description  | ('a' * 8192)          | true
        :description  | ('a' * 8193)          | false
        :urls         | ['a' * 512]           | true
        :urls         | ['a' * 513]           | false
        :urls         | Array.new(20) { 'a' } | true
        :urls         | Array.new(21) { 'a' } | false
      end

      with_them do
        subject(:advisory) { build(:pm_advisory, attribute => value).valid? }

        it { is_expected.to eq(is_valid) }
      end
    end

    describe 'identifier validation' do
      subject { build(:pm_advisory, identifiers: identifiers) }

      context 'when properly formatted list of identifiers' do
        let(:identifiers) do
          [
            create(:pm_identifier, :cve),
            create(:pm_identifier, type: "ghsa", name: "GHSA-9445-4cr6-336r", value: "GHSA-9445-4cr6-336r", url: "https://nvd.nist.gov/vuln/detail/CVE-2023-22797"),
            create(:pm_identifier, type: "gms", name: "GMS-2023-57", value: "GMS-2023-57")
          ]
        end

        it { is_expected.to be_valid }
      end

      context 'when more than max identifiers' do
        let(:identifiers) { create_list(:pm_identifier, 11, :cve) }

        it { is_expected.not_to be_valid }
      end

      context 'when identifier' do
        let(:base_identifier) do
          create(:pm_identifier, :cve)
        end

        let(:identifiers) { [identifier] }

        context 'with missing type' do
          let(:identifier) { base_identifier.reject { |k, _| k == :type } }

          it { is_expected.not_to be_valid }
        end

        context 'with missing name' do
          let(:identifier) { base_identifier.reject { |k, _| k == :name } }

          it { is_expected.not_to be_valid }
        end

        context 'with missing url' do
          let(:identifier) { base_identifier.reject { |k, _| k == :url } }

          it { is_expected.to be_valid }
        end

        context 'with missing value' do
          let(:identifier) { base_identifier.reject { |k, _| k == :value } }

          it { is_expected.not_to be_valid }
        end
      end
    end
  end
end
