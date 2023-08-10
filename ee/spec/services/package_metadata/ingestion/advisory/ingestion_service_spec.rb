# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Ingestion::Advisory::IngestionService, feature_category: :software_composition_analysis do
  describe '.execute' do
    subject(:execute) { described_class.execute(import_data) }

    describe 'transaction' do
      let(:import_data) { build_list(:pm_advisory_data_object, 10) }

      context 'when no errors' do
        it 'uses package metadata application record' do
          expect(PackageMetadata::ApplicationRecord).to receive(:transaction)
          execute
        end

        it 'adds new advisories and affected packages' do
          expect { execute }
            .to change { PackageMetadata::Advisory.count }.by(10)
            .and change { PackageMetadata::AffectedPackage.count }.by(10)
        end

        context 'and advisory scanning is enabled' do
          before do
            stub_feature_flags(dependency_scanning_on_advisory_ingestion: true)
          end

          it 'publishes all ingested advisories to the event store' do
            received_events = []
            allow(Gitlab::EventStore).to receive(:publish) do |event|
              received_events << event
            end

            execute

            received_advisory_ids = received_events.map { |event| event.data[:advisory_id] }
            received_advisories = PackageMetadata::Advisory.where(id: received_advisory_ids)
              .pluck(:source_xid, :advisory_xid).sort
            imported_advisories = import_data.map { |obj| [obj.source_xid, obj.advisory_xid] }.sort

            expect(received_advisories).to eq(imported_advisories)
          end
        end

        context 'and advisory scanning is disabled' do
          before do
            stub_feature_flags(dependency_scanning_on_advisory_ingestion: false)
          end

          it 'does not publish anything to the event store' do
            expect(Gitlab::EventStore).not_to receive(:publish)

            execute
          end
        end
      end

      context 'when error occurs' do
        context 'when an advisory fails json validation but the affected packages are valid' do
          let(:valid_advisory) do
            build(:pm_advisory_data_object, advisory_xid: 'valid-advisory',
              affected_packages: [build(:pm_affected_package_data_object,
                package_name: 'package-with-valid-advisory')])
          end

          let(:invalid_advisory) do
            build(:pm_advisory_data_object, identifiers: [{ key: 'invalid-json' }], advisory_xid: 'invalid-advisory',
              affected_packages: [build(:pm_affected_package_data_object,
                package_name: 'package-with-invalid-advisory')])
          end

          let(:import_data) { [invalid_advisory, valid_advisory] }

          it 'does not create DB records for the affected package belonging to the invalid advisory' do
            execute

            expect(PackageMetadata::AffectedPackage.where(package_name: 'package-with-invalid-advisory')).not_to exist
          end

          it 'only adds a single advisory and affected package to the DB' do
            expect { execute }
              .to change { PackageMetadata::Advisory.count }.from(0).to(1)
              .and change { PackageMetadata::AffectedPackage.count }.from(0).to(1)
          end

          it 'associates the affected package with the parent advisory' do
            execute

            advisory = PackageMetadata::Advisory.where(advisory_xid: valid_advisory.advisory_xid).first
            expect(advisory.affected_packages.first.package_name).to eql('package-with-valid-advisory')
          end
        end

        context 'when the error is unrecoverable' do
          it 'rolls back changes' do
            expect(PackageMetadata::Ingestion::Advisory::AdvisoryIngestionTask)
              .to receive(:execute).and_raise(StandardError)
            expect { execute }
            .to raise_error(StandardError)
            .and not_change(PackageMetadata::AffectedPackage, :count)
            .and not_change(PackageMetadata::Advisory, :count)
          end
        end
      end
    end
  end
end
