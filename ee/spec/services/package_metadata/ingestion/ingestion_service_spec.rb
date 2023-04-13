# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Ingestion::IngestionService, feature_category: :software_composition_analysis do
  describe '.execute' do
    let(:import_data) { build_list(:pm_data_object, 4) }
    let(:tasks) do
      [
        PackageMetadata::Ingestion::Tasks::IngestPackages,
        PackageMetadata::Ingestion::Tasks::IngestPackageVersions,
        PackageMetadata::Ingestion::Tasks::IngestLicenses,
        PackageMetadata::Ingestion::Tasks::IngestPackageVersionLicenses
      ]
    end

    subject(:execute) { described_class.execute(import_data) }

    it 'calls each task in order' do
      expect(tasks)
        .to all(receive(:execute)
        .with(kind_of(PackageMetadata::Ingestion::DataMap))
        .ordered)
      execute
    end

    describe 'transaction' do
      let(:import_data) { build_list(:pm_data_object, 1) }

      context 'and when every task executes without error' do
        it 'all updates are committed' do
          execute
          expect(PackageMetadata::Package.count).to eq(1)
          expect(PackageMetadata::PackageVersion.count).to eq(1)
          expect(PackageMetadata::License.count).to eq(1)
          expect(PackageMetadata::PackageVersionLicense.count).to eq(1)
        end
      end

      [
        PackageMetadata::Ingestion::Tasks::IngestPackages,
        PackageMetadata::Ingestion::Tasks::IngestPackageVersions,
        PackageMetadata::Ingestion::Tasks::IngestLicenses,
        PackageMetadata::Ingestion::Tasks::IngestPackageVersionLicenses
      ].each do |task|
        context "but when #{task} has an error" do
          before do
            allow(task).to receive(:execute).and_raise(StandardError)
          end

          it 'all updates are rolled back' do
            expect { execute }.to raise_error(StandardError)
            expect(PackageMetadata::Package.count).to eq(0)
            expect(PackageMetadata::PackageVersion.count).to eq(0)
            expect(PackageMetadata::License.count).to eq(0)
            expect(PackageMetadata::PackageVersionLicense.count).to eq(0)
          end
        end
      end
    end

    describe 'created data' do
      let(:import_data) do
        [
          build(:pm_data_object, purl_type: 'maven', name: 'libcuckoo', version: '0.3.0', license: 'Apache-2.0'),
          build(:pm_data_object, purl_type: 'npm', name: 'libcuckoo', version: '0.3.0', license: 'Apache-2.0'),
          build(:pm_data_object, purl_type: 'npm', name: 'libcuckoo', version: '0.4.0', license: 'MIT'),
          build(:pm_data_object, purl_type: 'npm', name: 'libcuckoo', version: '0.4.1', license: 'Apache-2.0')
        ]
      end

      let(:package_versions) { package_version_licenses.map(&:package_version).uniq }
      let(:packages) { package_versions.map(&:package).uniq }
      let(:licenses) { package_version_licenses.map(&:license).uniq }

      subject(:execute) { described_class.execute(import_data) }

      it 'has the expected relationships' do
        execute

        package = PackageMetadata::Package.find_by(purl_type: 'maven', name: 'libcuckoo')
        expect(package.package_versions.pluck(:version)).to match_array(['0.3.0'])
        licenses = package.package_versions.flat_map(&:licenses)
        expect(licenses.pluck(:spdx_identifier)).to match_array(['Apache-2.0'])

        package = PackageMetadata::Package.find_by(purl_type: 'npm', name: 'libcuckoo')
        expect(package.package_versions.pluck(:version)).to match_array(['0.3.0', '0.4.0', '0.4.1'])
        licenses = package.package_versions.flat_map(&:licenses)
        expect(licenses.pluck(:spdx_identifier).uniq).to match_array(['MIT', 'Apache-2.0'])
      end
    end
  end
end
