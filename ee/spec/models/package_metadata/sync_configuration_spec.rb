# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::SyncConfiguration, feature_category: :license_compliance do
  describe '.all' do
    subject(:registries) { described_class.all }

    it 'returns a configuration instance for each known purl type' do
      expect(registries).to match_array([
        have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
          version_format: described_class::VERSION_FORMAT, purl_type: 'composer'),
        have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
          version_format: described_class::VERSION_FORMAT, purl_type: 'conan'),
        have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
          version_format: described_class::VERSION_FORMAT, purl_type: 'gem'),
        have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
          version_format: described_class::VERSION_FORMAT, purl_type: 'golang'),
        have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
          version_format: described_class::VERSION_FORMAT, purl_type: 'maven'),
        have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
          version_format: described_class::VERSION_FORMAT, purl_type: 'npm'),
        have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
          version_format: described_class::VERSION_FORMAT, purl_type: 'nuget'),
        have_attributes(storage_type: :gcp, base_uri: described_class::BUCKET_NAME,
          version_format: described_class::VERSION_FORMAT, purl_type: 'pypi')
      ])
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
end
