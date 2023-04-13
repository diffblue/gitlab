# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Ingestion::Tasks::IngestPackages, feature_category: :software_composition_analysis do
  describe '#execute' do
    let(:data_map) { PackageMetadata::Ingestion::DataMap.new(import_data) }

    context 'when import data is new' do
      let(:import_data) { build_list(:pm_data_object, 4) }

      it 'adds the new records' do
        expect { described_class.execute(data_map) }.to change { PackageMetadata::Package.count }.by(4)
        expect { described_class.execute(data_map) }.to not_change { PackageMetadata::Package.count }
      end

      it 'updates the data map' do
        described_class.execute(data_map)
        expected_ids = PackageMetadata::Package.all.pluck(:id)
        actual_ids = import_data.map { |data_object| data_map.get_package_id(data_object.purl_type, data_object.name) }
        expect(expected_ids).to match_array(actual_ids)
      end
    end

    context 'when import data exists' do
      let!(:import_data) { create_list(:pm_data_object, 4, :with_package) }

      it 'does not add records' do
        expect { described_class.execute(data_map) }.to not_change { PackageMetadata::Package.count }
      end

      it 'updates the data map' do
        described_class.execute(data_map)
        expected_ids = PackageMetadata::Package.all.pluck(:id)
        actual_ids = import_data.map { |data_object| data_map.get_package_id(data_object.purl_type, data_object.name) }
        expect(expected_ids).to match_array(actual_ids)
      end
    end

    context 'when normalizing names' do
      context 'with pypi packages' do
        let(:import_data) do
          [
            build(:pm_data_object, name: 'Foo', purl_type: 'pypi'),
            build(:pm_data_object, name: 'fOo', purl_type: 'pypi'),
            build(:pm_data_object, name: 'foO', purl_type: 'pypi')
          ]
        end

        it 'treats case variations as non unique' do
          expect { described_class.execute(data_map) }.to change { PackageMetadata::Package.count }.by(1)
          expect { described_class.execute(data_map) }.to not_change { PackageMetadata::Package.count }
        end

        it 'normalizes the original package name' do
          described_class.execute(data_map)
          names = PackageMetadata::Package.all.pluck(:name)
          expect(names).to eq(['foo'])
        end
      end

      context 'with non-pypi packages' do
        let(:import_data) do
          [
            build(:pm_data_object, name: 'Foo', purl_type: 'composer'),
            build(:pm_data_object, name: 'fOo', purl_type: 'composer'),
            build(:pm_data_object, name: 'foO', purl_type: 'composer')
          ]
        end

        it 'treats case variations as unique' do
          expect { described_class.execute(data_map) }.to change { PackageMetadata::Package.count }.by(3)
          expect { described_class.execute(data_map) }.to not_change { PackageMetadata::Package.count }
        end

        it 'keeps the original package names' do
          described_class.execute(data_map)
          names = PackageMetadata::Package.all.pluck(:name)
          expect(names).to match_array(%w[Foo fOo foO])
        end
      end
    end
  end
end
