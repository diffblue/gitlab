# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Ingestion::Tasks::IngestLicenses, feature_category: :software_composition_analysis do
  describe '#execute' do
    let(:data_map) { PackageMetadata::Ingestion::DataMap.new(import_data) }

    context 'when import data is new' do
      let(:import_data) { build_list(:pm_data_object, 4, :with_license) }

      it 'adds the new records' do
        expect { described_class.execute(data_map) }.to change { PackageMetadata::License.count }.by(4)
        expect { described_class.execute(data_map) }.to not_change { PackageMetadata::License.count }
      end

      it 'updates the data map' do
        described_class.execute(data_map)
        expected_ids = PackageMetadata::License.all.pluck(:id)
        actual_ids = import_data.map { |data_object| data_map.get_license_id(data_object.license) }.uniq
        expect(actual_ids).to match_array(expected_ids)
      end
    end

    context 'when import data exists' do
      let!(:import_data) { create_list(:pm_data_object, 4, :with_license) }

      it 'does not add records' do
        expect { described_class.execute(data_map) }.to not_change { PackageMetadata::License.count }
      end

      it 'updates the data map' do
        described_class.execute(data_map)
        expected_ids = PackageMetadata::License.all.pluck(:id)
        actual_ids = import_data.map { |data_object| data_map.get_license_id(data_object.license) }.uniq
        expect(actual_ids).to match_array(expected_ids)
      end
    end
  end
end
