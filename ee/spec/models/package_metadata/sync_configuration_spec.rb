# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::SyncConfiguration, feature_category: :software_composition_analysis do
  before do
    stub_feature_flags(package_metadata_synchronization: true)
    stub_feature_flags(compressed_package_metadata_synchronization: false)
  end

  describe '.all_by_enabled_purl_type' do
    subject(:configurations) { described_class.all_by_enabled_purl_type }

    context 'with all purl types allowed to sync' do
      before do
        # stub application setting with all available at the moment package metadata types
        stub_application_setting(package_metadata_purl_types: Enums::PackageMetadata.purl_types.values)
      end

      context 'when only feature flag package_metadata_synchronization is set' do
        before do
          stub_feature_flags(package_metadata_synchronization: true)
          stub_feature_flags(compressed_package_metadata_synchronization: false)
        end

        it 'returns a configuration instance for each known purl type' do
          expect(configurations).to match_array([
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'composer'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'conan'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'gem'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'golang'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'maven'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'npm'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'nuget'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'pypi'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'apk'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'rpm'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'deb'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'cbl_mariner')
          ])
        end
      end

      context 'when only feature flag compressed_package_metadata_synchronization is set' do
        before do
          stub_feature_flags(package_metadata_synchronization: false)
          stub_feature_flags(compressed_package_metadata_synchronization: true)
        end

        it 'returns a configuration instance for each known purl type' do
          expect(configurations).to match_array([
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'composer'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'conan'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'gem'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'golang'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'maven'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'npm'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'nuget'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'pypi'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'apk'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'rpm'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'deb'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'cbl_mariner')
          ])
        end
      end

      context 'when both feature flags are set' do
        before do
          stub_feature_flags(package_metadata_synchronization: true)
          stub_feature_flags(compressed_package_metadata_synchronization: true)
        end

        it 'returns a configuration instance for each known purl type' do
          expect(configurations).to match_array([
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'composer'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'conan'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'gem'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'golang'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'maven'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'npm'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'nuget'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'pypi'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'apk'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'rpm'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'deb'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v2', purl_type: 'cbl_mariner'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'composer'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'conan'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'gem'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'golang'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'maven'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'npm'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'nuget'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'pypi'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'apk'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'rpm'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'deb'),
            have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
              version_format: 'v1', purl_type: 'cbl_mariner')
          ])
        end
      end
    end

    context 'with some purl types allowed to sync' do
      before do
        stub_application_setting(package_metadata_purl_types: [1, 5])
      end

      it 'returns a configuration instance only for selected types' do
        expect(configurations).to match_array([
          have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
            version_format: 'v1', purl_type: 'composer'),
          have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
            version_format: 'v1', purl_type: 'maven')
        ])
      end
    end

    context 'with none purl types allowed to sync' do
      it 'returns an empty array' do
        expect(configurations).to be_empty
      end
    end
  end

  describe '.get_storage_type' do
    subject(:storage_type) { described_class.get_storage_type }

    before do
      allow(File).to receive(:exist?).with(described_class.archive_path).and_return(file_exists)
    end

    context 'when offline path exists' do
      let(:file_exists) { true }

      it { is_expected.to eq(:offline) }
    end

    context 'when no offline path' do
      let(:file_exists) { false }

      it { is_expected.to eq(:gcp) }
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
