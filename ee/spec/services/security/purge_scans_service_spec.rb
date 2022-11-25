# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::PurgeScansService do
  describe 'class interface' do
    let(:batchable_relation) { instance_double(Security::Scan.all.class) }
    let(:mock_service_object) { instance_double(described_class, execute: true) }

    describe '.purge_stale_records' do
      let(:mock_relation) do
        instance_double(Security::Scan.all.class, ordered_by_created_at_and_id: batchable_relation)
      end

      subject(:purge_stale_records) { described_class.purge_stale_records }

      before do
        allow(Security::Scan).to receive(:stale).and_return(mock_relation)
        allow(described_class).to receive(:new).and_return(mock_service_object)
      end

      it 'instantiates the service class with stale scans' do
        purge_stale_records

        expect(described_class).to have_received(:new).with(batchable_relation)
        expect(mock_service_object).to have_received(:execute)
      end
    end

    describe '.purge_by_build_ids' do
      let(:build_ids) { [1, 2] }

      subject(:purge_by_build_ids) { described_class.purge_by_build_ids(build_ids) }

      before do
        allow(Security::Scan).to receive(:by_build_ids).and_return(batchable_relation)
        allow(described_class).to receive(:new).and_return(mock_service_object)
      end

      it 'instantiates the service class with scans by given build ids' do
        purge_by_build_ids

        expect(Security::Scan).to have_received(:by_build_ids).with(build_ids)
        expect(described_class).to have_received(:new).with(batchable_relation)
        expect(mock_service_object).to have_received(:execute)
      end
    end
  end

  describe '#execute' do
    let(:security_scans) { create_list(:security_scan, 2) }
    let(:relation) { Security::Scan.where(id: security_scans.map(&:id)) }
    let(:service_object) { described_class.new(relation) }

    subject(:purge_scans) { service_object.execute }

    it 'marks the security scans as purged by given relation' do
      expect { purge_scans }.to change { Security::Scan.purged.count }.from(0).to(2)
    end

    context 'when there are more than maximum stale scans size allowed to be updated' do
      before do
        stub_const("#{described_class}::MAX_STALE_SCANS_SIZE", 1)
        stub_const("#{described_class}::SCAN_BATCH_SIZE", 1)
      end

      it 'marks only the allowed amount of security scans as purged' do
        expect { purge_scans }.to change { Security::Scan.purged.count }.from(0).to(1)
      end
    end
  end
end
