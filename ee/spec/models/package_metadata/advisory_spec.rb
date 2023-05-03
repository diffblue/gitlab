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

    describe 'length validation' do
      where(:attribute, :max_length) do
        :advisory_xid | 36
        :title | 256
        :description | 8192
      end

      with_them do
        it { is_expected.to validate_length_of(attribute).is_at_most(max_length) }
      end
    end

    describe 'url validation' do
      subject { build(:pm_advisory, urls: urls) }

      let(:urls) { [url] }

      context 'when url does not exceed max length' do
        let(:url) { 'a' * 512 }

        it { is_expected.to be_valid }
      end

      context 'when url exceeds max length' do
        let(:url) { 'a' * 513 }

        it { is_expected.not_to be_valid }
      end
    end

    describe 'identifier validation' do
      subject { build(:pm_advisory, identifiers: identifiers) }

      context 'when properly formatted list of identifiers' do
        let(:identifiers) do
          [
            { type: "cve", name: "CVE-2023-22797", value: "CVE-2023-22797",
              url: "https://nvd.nist.gov/vuln/detail/CVE-2023-22797" },
            { type: "ghsa", name: "GHSA-9445-4cr6-336r", value: "GHSA-9445-4cr6-336r",
              url: "https://nvd.nist.gov/vuln/detail/CVE-2023-22797" },
            { type: "gms", name: "GMS-2023-57", value: "GMS-2023-57" }
          ]
        end

        it { is_expected.to be_valid }
      end

      context 'when more than max identifiers' do
        let(:identifiers) do
          Array.new(11) { |_i| { type: "cve", name: "CVE-2023-22797", value: "CVE-2023-22797", url: "https://nvd.nist.gov/vuln/detail/CVE-2023-22797" } }
        end

        it { is_expected.not_to be_valid }
      end

      context 'when identifier' do
        let(:base_identifier) do
          {
            type: 'CVE',
            name: 'CVE-1111',
            url: 'http://foo.com/cve/1111',
            value: 'CVE-1111'
          }
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
