# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Ingestion::Tasks::IngestPackageVersionLicenses, feature_category: :software_composition_analysis do
  describe '#execute' do
    let(:data_map) { PackageMetadata::Ingestion::DataMap.new(import_data) }

    context 'when import data is new' do
      let!(:import_data) { create_list(:pm_data_object, 4, :with_all_relations) }

      it 'adds the new records' do
        expect { described_class.execute(data_map) }.to change { PackageMetadata::PackageVersionLicense.count }.by(4)
        expect { described_class.execute(data_map) }.to not_change { PackageMetadata::PackageVersionLicense.count }
      end
    end

    context 'when import data exists' do
      let!(:import_data) { create_list(:pm_data_object, 4, :with_all_relations_joined) }

      it 'does not add records' do
        expect { described_class.execute(data_map) }.to not_change { PackageMetadata::PackageVersionLicense.count }
      end
    end
  end
end
