# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Ingestion::CompressedPackage::PackageIngestionTask, feature_category: :software_composition_analysis do
  describe '.execute' do
    let(:import_data) do
      [
        build(:pm_compressed_data_object, purl_type: 'gem', name: 'rails',
          default_licenses: ['MIT'], lowest_version: 'v0.0.1', highest_version: 'v1.0.0',
          other_licenses: [{ 'licenses' => %w[Apache APSL], 'versions' => ['v0.9.0', 'v0.9.1'] }]),
        build(:pm_compressed_data_object, purl_type: 'gem', name: 'activerecord', default_licenses: ['MIT'],
          lowest_version: 'v0.1.0', highest_version: 'v10',
          other_licenses: [{ 'licenses' => ['GPL'], 'versions' => ['v0.1.0'] }]),
        build(:pm_compressed_data_object, purl_type: 'gem', name: '0mq', default_licenses: ['MIT-2'],
          lowest_version: 'v0.0.1', highest_version: 'v1.0.0', other_licenses: []),
        build(:pm_compressed_data_object, purl_type: 'gem', name: 'redis', default_licenses: ['LGPL'],
          lowest_version: 'v1.0.1', highest_version: 'v9.5.1', other_licenses: [])
      ]
    end

    let(:license_map) do
      {
        'MIT' => 1,
        'Apache' => 2,
        'APSL' => 3,
        'GPL' => 4,
        'MIT-2' => 5,
        'LGPL' => 6
      }
    end

    let!(:existing_package) do
      create(:pm_package, purl_type: 'gem', name: 'rails', licenses: [[1], '0.0.0', '100.1.2.3', []])
    end

    subject(:execute) { described_class.execute(import_data, license_map) }

    context 'when valid packages' do
      it 'adds all packages in import data' do
        expect { execute }
          .to change { PackageMetadata::Package.all.pluck(:purl_type, :name) }
          .from([%w[gem rails]])
          .to([%w[gem rails], %w[gem activerecord], %w[gem 0mq], %w[gem redis]])
      end

      it 'is updates existing packages' do
        expect { execute }
          .to change { existing_package.reload.licenses }
          .from([[1], '0.0.0', '100.1.2.3', []])
          .to([[1], 'v0.0.1', 'v1.0.0', [[[2, 3], ['v0.9.0', 'v0.9.1']]]])
      end

      it 'replaces spdx_identifiers with corresponding ids from license map' do
        execute
        expect(PackageMetadata::Package.find_by(purl_type: 'gem', name: 'rails').licenses)
          .to match_array([[1], 'v0.0.1', 'v1.0.0', [[[2, 3], ['v0.9.0', 'v0.9.1']]]])
        expect(PackageMetadata::Package.find_by(purl_type: 'gem', name: 'activerecord').licenses)
          .to match_array([[1], 'v0.1.0', 'v10', [[[4], ['v0.1.0']]]])
        expect(PackageMetadata::Package.find_by(purl_type: 'gem', name: '0mq').licenses)
          .to match_array([[5], 'v0.0.1', 'v1.0.0', []])
        expect(PackageMetadata::Package.find_by(purl_type: 'gem', name: 'redis').licenses)
          .to match_array([[6], 'v1.0.1', 'v9.5.1', []])
      end
    end

    context 'when invalid packages' do
      let(:valid_package) { build(:pm_compressed_data_object) }
      let(:invalid_package) { build(:pm_compressed_data_object, default_licenses: []) }
      let(:import_data) { [valid_package, invalid_package] }

      it "creates only valid packages" do
        expect { execute }
          .to change { PackageMetadata::Package.all.pluck(:purl_type, :name) }
          .from([%w[gem rails]])
          .to([%w[gem rails], [valid_package.purl_type, valid_package.name]])
      end

      it 'logs invalid packages as an error' do
        expect(::Gitlab::AppJsonLogger)
          .to receive(:error)
          .with(class: described_class.name,
            message: "invalid package #{invalid_package.purl_type}/#{invalid_package.name}",
            errors: { licenses: ['must be a valid json schema'] })
        execute
      end
    end
  end
end
