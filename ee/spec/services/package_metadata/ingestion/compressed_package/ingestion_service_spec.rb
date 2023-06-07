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
    end
  end
end
