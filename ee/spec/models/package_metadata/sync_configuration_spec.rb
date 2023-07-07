# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::SyncConfiguration, feature_category: :software_composition_analysis do
  before do
    stub_feature_flags(package_metadata_synchronization: true)
    stub_feature_flags(compressed_package_metadata_synchronization: false)
  end

  describe 'configs based on enabled purl types' do
    using RSpec::Parameterized::TableSyntax

    let(:all_purl_types) { Enums::PackageMetadata.purl_types.values }

    shared_examples_for 'it returns all enabled sync configs' do
      let(:purl_type_map) { Enums::PackageMetadata::PURL_TYPES.invert }
      before do
        stub_application_setting(package_metadata_purl_types: enabled_purl_types)
      end

      specify do
        expected = []
        expected_version_formats.each do |version_format|
          expected += enabled_purl_types.map do |purl_type|
            have_attributes(data_type: expected_data_type, storage_type: :gcp, base_uri: expected_bucket,
              version_format: version_format, purl_type: purl_type_map[purl_type])
          end
        end

        expect(configurations.size).to eq(expected_num_configs)
        expect(configurations).to match_array(expected)
      end
    end

    context 'when syncing licenses' do
      let(:expected_data_type) { 'licenses' }
      let(:expected_bucket) { described_class::STORAGE_LOCATIONS.dig(:licenses, :gcp) }

      subject(:configurations) { described_class.all_configs_for_licenses }

      where(:sync_v1, :sync_v2, :expected_version_formats, :enabled_purl_types, :expected_num_configs) do
        true  | false | ['v1']        | ref(:all_purl_types)  | 12
        false | true  | ['v2']        | ref(:all_purl_types)  | 12
        true  | true  | %w[v1 v2]     | ref(:all_purl_types)  | 24
        false | false | []            | ref(:all_purl_types)  | 0
        true  | false | ['v1']        | [1, 5]                | 2
        false | true  | ['v2']        | [1, 5]                | 2
        true  | true  | %w[v1 v2]     | [1, 5]                | 4
        false | false | []            | [1, 5]                | 0
        true  | false | ['v1']        | []                    | 0
        false | true  | ['v2']        | []                    | 0
        true  | true  | %w[v1 v2]     | []                    | 0
        false | false | []            | []                    | 0
      end

      with_them do
        before do
          stub_feature_flags(package_metadata_synchronization: sync_v1)
          stub_feature_flags(compressed_package_metadata_synchronization: sync_v2)
        end

        it_behaves_like 'it returns all enabled sync configs'
      end
    end

    context 'when syncing advisories' do
      let(:expected_data_type) { 'advisories' }
      let(:expected_bucket) { described_class::STORAGE_LOCATIONS.dig(:advisories, :gcp) }
      let(:expected_version_formats) { ['v2'] }

      subject(:configurations) { described_class.all_configs_for_advisories }

      where(:enabled_purl_types, :expected_num_configs) do
        ref(:all_purl_types)  | 12
        [1, 5]                | 2
        []                    | 0
      end

      with_them do
        it_behaves_like 'it returns all enabled sync configs'
      end
    end
  end

  describe '.get_storage_type_and_base_uri_for' do
    subject(:get_storage_and_base_uri_for) { described_class.get_storage_and_base_uri_for(data_type) }

    before do
      allow(File).to receive(:exist?).with(described_class::STORAGE_LOCATIONS.dig(:advisories, :offline))
        .and_return(file_exists)
      allow(File).to receive(:exist?).with(described_class::STORAGE_LOCATIONS.dig(:licenses, :offline))
        .and_return(file_exists)
    end

    context 'when offline path exists' do
      let(:file_exists) { true }

      context 'and the data_type is advisories' do
        let(:data_type) { 'advisories' }

        it { is_expected.to match_array([:offline, described_class::STORAGE_LOCATIONS.dig(:advisories, :offline)]) }
      end

      context 'and the data_type is licenses' do
        let(:data_type) { 'licenses' }

        it { is_expected.to match_array([:offline, described_class::STORAGE_LOCATIONS.dig(:licenses, :offline)]) }
      end
    end

    context 'when offline path does not exist' do
      let(:file_exists) { false }

      context 'and the data_type is advisories' do
        let(:data_type) { 'advisories' }

        it { is_expected.to match_array([:gcp, described_class::STORAGE_LOCATIONS.dig(:advisories, :gcp)]) }
      end

      context 'and the data_type is licenses' do
        let(:data_type) { 'licenses' }

        it { is_expected.to match_array([:gcp, described_class::STORAGE_LOCATIONS.dig(:licenses, :gcp)]) }
      end
    end
  end

  describe '.registry' do
    ::Enums::Sbom::PURL_TYPES.each do |purl_type, _|
      context "when purl type is #{purl_type}" do
        it "returns a non-default value" do
          expect(described_class.registry_id(purl_type)).not_to be_nil
        end
      end
    end
  end
end
