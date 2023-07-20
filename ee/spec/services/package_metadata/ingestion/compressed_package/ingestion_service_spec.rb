# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Ingestion::CompressedPackage::IngestionService, feature_category: :software_composition_analysis do
  describe '.execute' do
    subject(:execute) { described_class.execute(import_data) }

    describe 'transaction' do
      let(:import_data) { build_list(:pm_compressed_data_object, 10) }

      context 'when no errors' do
        it 'uses package metadata application record' do
          expect(PackageMetadata::ApplicationRecord).to receive(:transaction)
          execute
        end

        it 'adds new licenses' do
          expect { execute }
            .to change { PackageMetadata::License.all.size }.by(2)
            .and change { PackageMetadata::Package.all.size }.by(10)
        end
      end

      context 'when error occurs' do
        it 'rolls back changes' do
          expect(PackageMetadata::Ingestion::CompressedPackage::PackageIngestionTask)
            .to receive(:execute).and_raise(StandardError)
          expect { execute }
          .to raise_error(StandardError)
          .and not_change(PackageMetadata::License, :count)
          .and not_change(PackageMetadata::Package, :count)
        end
      end

      context 'when import data contains both default and other licenses' do
        let(:import_data) do
          build_list(:pm_compressed_data_object, 1, name: 'requests', purl_type: 'pypi',
            default_licenses: ['Apache-1.0', 'Apache-2.0'],
            lowest_version: '2.3.0',
            highest_version: '2.31.0',
            other_licenses: [
              { "licenses" => ["ISC"], "versions" => ["0.10.2"] },
              { "licenses" => ["Apache-1.0"], "versions" => ["1.0.0"] },
              { "licenses" => ["unknown"], "versions" => ["0.13.2", "0.13.5"] },
              { "licenses" => ["MIT"], "versions" => ["0.0.1"] }
            ]
          )
        end

        let(:package) { PackageMetadata::Package.first }
        let(:license_ids) { PackageMetadata::License.all.pluck(:spdx_identifier, :id).to_h }
        let(:default_licenses) { package.licenses[0] }
        let(:lowest_version) { package.licenses[1] }
        let(:highest_version) { package.licenses[2] }
        let(:other_licenses) { package.licenses[3] }

        it 'adds the expected package and license data', :aggregate_failures do
          described_class.execute(import_data)
          expect(package.purl_type).to eq('pypi')
          expect(package.name).to eq('requests')
          expect(default_licenses)
            .to match_array([license_ids['Apache-1.0'], license_ids['Apache-2.0']])
          expect(lowest_version).to eq('2.3.0')
          expect(highest_version).to eq('2.31.0')
          expect(other_licenses)
            .to eq([
              [[license_ids['ISC']], ['0.10.2']],
              [[license_ids['Apache-1.0']], ['1.0.0']],
              [[license_ids['unknown']], ['0.13.2', '0.13.5']],
              [[license_ids['MIT']], ['0.0.1']]
            ])
        end
      end
    end
  end
end
