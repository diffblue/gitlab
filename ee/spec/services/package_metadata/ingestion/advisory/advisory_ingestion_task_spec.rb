# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Ingestion::Advisory::AdvisoryIngestionTask, feature_category: :software_composition_analysis do
  describe '.execute' do
    let_it_be(:advisory_xid) { 'some-uuid-value' }

    let!(:existing_advisory) do
      create(:pm_advisory, advisory_xid: advisory_xid, title: 'advisory title')
    end

    let(:import_data) do
      [
        build(:pm_advisory_data_object, advisory_xid: advisory_xid, title: 'updated advisory title'),
        build(:pm_advisory_data_object)
      ]
    end

    subject(:execute) { described_class.execute(import_data) }

    context 'when advisories are valid' do
      it 'adds all new advisories in import data' do
        expect { execute }.to change { PackageMetadata::Advisory.count }.from(1).to(2)
      end

      it 'updates existing advisories' do
        expect { execute }
          .to change { existing_advisory.reload.title }
          .from('advisory title')
          .to('updated advisory title')
      end

      it 'returns the advisory database id values as a map' do
        actual_advisory_map = execute
        expected_advisory_map = PackageMetadata::Advisory.all.to_h { |advisory| [advisory.advisory_xid, advisory.id] }
        expect(actual_advisory_map).to eq(expected_advisory_map)
      end
    end

    context 'when advisories are invalid' do
      let(:valid_advisory) { build(:pm_advisory_data_object) }
      let(:invalid_advisory) { build(:pm_advisory_data_object, identifiers: [{ key: 'invalid-json' }]) }
      let(:import_data) { [valid_advisory, invalid_advisory] }

      it 'creates only valid advisories' do
        expect { execute }.to change { PackageMetadata::Advisory.count }.by(1)
      end

      it 'logs invalid advisories as an error' do
        expect(::Gitlab::AppJsonLogger)
          .to receive(:error)
          .with(class: described_class.name,
            message: "invalid advisory",
            source_xid: invalid_advisory.source_xid,
            advisory_xid: invalid_advisory.advisory_xid,
            errors: { identifiers: ['must be a valid json schema'] })
        execute
      end
    end
  end
end
