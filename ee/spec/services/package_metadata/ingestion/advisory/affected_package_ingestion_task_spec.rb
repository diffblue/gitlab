# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Ingestion::Advisory::AffectedPackageIngestionTask, feature_category: :software_composition_analysis do
  describe '.execute' do
    let_it_be(:advisory_xid) { 'some-uuid-value' }

    let!(:existing_advisory) do
      create(:pm_advisory, advisory_xid: advisory_xid)
    end

    let!(:existing_affected_package) do
      create(:pm_affected_package, advisory: existing_advisory)
    end

    let(:import_data) do
      [
        build(:pm_advisory_data_object, advisory_xid: advisory_xid,
          affected_packages: [
            build(:pm_affected_package_data_object,
              package_name: existing_affected_package.package_name,
              fixed_versions: %w[9.9.9],
              versions: [{ 'number' => '1.2.4',
                           'commit' => { 'tags' => ['v1.2.4-tag'], 'sha' => '295cf0778821bf08681e2bd0ef0e6cad04fc3001',
                                         'timestamp' => '20190626162700' } }])
          ]),
        build(:pm_advisory_data_object)
      ]
    end

    let(:advisory_map) { PackageMetadata::Ingestion::Advisory::AdvisoryIngestionTask.execute(import_data) }

    subject(:execute) { described_class.execute(import_data, advisory_map) }

    context 'when affected packages are valid' do
      it 'adds all new affected packages in import data' do
        expect { execute }.to change { PackageMetadata::AffectedPackage.count }.from(1).to(2)
      end

      it 'updates existing affected packages' do
        expect { execute }
          .to change { existing_affected_package.reload.fixed_versions }
          .from(%w[5.2.1.1])
          .to(%w[9.9.9])
          .and change { existing_affected_package.reload.versions }
          .from([{ 'number' => '1.2.3',
                   'commit' => { 'tags' => ['v1.2.3-tag'], 'sha' => '295cf0778821bf08681e2bd0ef0e6cad04fc3001',
                                 'timestamp' => '20190626162700' } }])
          .to([{ 'number' => '1.2.4',
                 'commit' => { 'tags' => ['v1.2.4-tag'], 'sha' => '295cf0778821bf08681e2bd0ef0e6cad04fc3001',
                               'timestamp' => '20190626162700' } }])
      end
    end

    context 'when affected packages are invalid' do
      let(:advisory_with_valid_affected_package) { build(:pm_advisory_data_object) }
      let(:invalid_affected_package) do
        build(:pm_affected_package_data_object, overridden_advisory_fields: 'invalid-json')
      end

      let(:advisory_with_invalid_affected_package) do
        build(:pm_advisory_data_object, affected_packages: [invalid_affected_package])
      end

      let(:import_data) { [advisory_with_valid_affected_package, advisory_with_invalid_affected_package] }

      it 'creates only valid affected packages' do
        expect { execute }.to change { PackageMetadata::AffectedPackage.count }.by(1)
      end

      it 'logs invalid affected packages as an error' do
        expect(::Gitlab::AppJsonLogger)
          .to receive(:error)
          .with(class: described_class.name,
            message: "invalid affected_package",
            purl_type: invalid_affected_package.purl_type,
            package_name: invalid_affected_package.package_name,
            distro_version: invalid_affected_package.distro_version,
            errors: { overridden_advisory_fields: ['must be a valid json schema'] })
        execute
      end
    end
  end
end
