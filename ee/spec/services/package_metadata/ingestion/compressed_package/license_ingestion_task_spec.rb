# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Ingestion::CompressedPackage::LicenseIngestionTask, feature_category: :software_composition_analysis do
  describe '.execute' do
    let(:import_data) do
      [
        build(:pm_compressed_data_object, purl_type: 'gem', name: 'rails',
          default_licenses: ['MIT'],
          other_licenses: [{ 'licenses' => %w[Apache APSL], 'versions' => ['v0.9.0', 'v0.9.1'] }]),
        build(:pm_compressed_data_object, purl_type: 'gem', name: 'activerecord',
          default_licenses: ['MIT'], other_licenses: [{ 'licenses' => ['GPL'], 'versions' => ['v0.1.0'] }]),
        build(:pm_compressed_data_object, purl_type: 'gem', name: '0mq', default_licenses: ['MIT-2'],
          other_licenses: []),
        build(:pm_compressed_data_object, purl_type: 'gem', name: 'redis', default_licenses: ['LGPL'],
          other_licenses: [])
      ]
    end

    let(:license_map) { { existing_license.spdx_identifier => existing_license.id } }

    let!(:existing_license) { create(:pm_license, spdx_identifier: 'MIT') }

    subject(:execute) { described_class.execute(import_data, license_map) }

    it 'creates any data not in pm_licenses' do
      expect { execute }
        .to change { PackageMetadata::License.all.pluck(:spdx_identifier).sort }
        .from(['MIT'])
        .to(%w[APSL Apache GPL LGPL MIT MIT-2])
    end

    it 'updates the license map with the ids of all newly inserted licenses' do
      execute
      expect(license_map).to eq(PackageMetadata::License.all.pluck(:spdx_identifier, :id).to_h)
    end
  end
end
