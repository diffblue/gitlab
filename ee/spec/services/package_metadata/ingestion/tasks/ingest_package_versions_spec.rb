# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Ingestion::Tasks::IngestPackageVersions, feature_category: :software_composition_analysis do
  describe '#execute' do
    let(:data_map) { PackageMetadata::Ingestion::DataMap.new(import_data) }

    context 'when import data is new' do
      let!(:import_data) { create_list(:pm_data_object, 4, :with_package) }

      it 'adds the new records' do
        expect { described_class.execute(data_map) }.to change { PackageMetadata::PackageVersion.count }.by(4)
        expect { described_class.execute(data_map) }.to not_change { PackageMetadata::PackageVersion.count }
      end

      it 'updates the data map' do
        described_class.execute(data_map)
        expected_ids = PackageMetadata::PackageVersion.all.pluck(:id)
        actual_ids = import_data.map do |data_object|
          data_map.get_package_version_id(data_object.purl_type, data_object.name, data_object.version)
        end
        expect(actual_ids).to match_array(expected_ids)
      end
    end

    context 'when import data exists' do
      let!(:import_data) { create_list(:pm_data_object, 4, :with_version) }

      it 'does not add records' do
        expect { described_class.execute(data_map) }.to not_change { PackageMetadata::PackageVersion.count }
      end

      it 'updates the data map' do
        described_class.execute(data_map)
        expected_ids = PackageMetadata::PackageVersion.all.pluck(:id)
        actual_ids = import_data.map do |data_object|
          data_map.get_package_version_id(data_object.purl_type, data_object.name, data_object.version)
        end
        expect(actual_ids).to match_array(expected_ids)
      end
    end

    context 'when data has duplicate package version rows' do
      let(:package) { create(:pm_package, name: 'foo') }
      let!(:import_data) do
        create_list(:pm_data_object, 2, :with_package, pm_package: package, version: '1.0.0')
      end

      it 'adds a single record for a unique package and version' do
        expect { described_class.execute(data_map) }.to change { PackageMetadata::PackageVersion.count }.by(1)
        expect { described_class.execute(data_map) }.to not_change { PackageMetadata::PackageVersion.count }
      end
    end
  end
end
