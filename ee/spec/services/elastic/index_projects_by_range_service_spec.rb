# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::IndexProjectsByRangeService, feature_category: :global_search do
  describe '#execute' do
    context 'when without project' do
      it 'does not err' do
        expect(ElasticFullIndexWorker).not_to receive(:bulk_perform_async)

        described_class.new.execute
      end
    end

    context 'when range not specified' do
      before do
        allow(::Project).to receive(:maximum).with(:id).and_return(described_class::DEFAULT_BATCH_SIZE + 1)
      end

      it 'schedules for all projects' do
        expect(ElasticFullIndexWorker).to receive(:bulk_perform_async).with([[1, 1000], [1001, 1001]])

        described_class.new.execute
      end

      it 'respects batch_size setting' do
        expect(ElasticFullIndexWorker).to receive(:bulk_perform_async).with([[1, 500], [501, 1000], [1001, 1001]])

        described_class.new.execute(batch_size: 500)
      end
    end

    context 'when range specified' do
      it 'schedules for projects within range' do
        expect(ElasticFullIndexWorker).to receive(:bulk_perform_async).with([[2, 5]])

        described_class.new.execute(start_id: 2, end_id: 5)
      end

      it 'respects batch_size setting' do
        expect(ElasticFullIndexWorker).to receive(:bulk_perform_async).with([[501, 1500], [1501, 1501]])

        described_class.new.execute(start_id: 501, end_id: 1501, batch_size: 1000)
      end
    end
  end
end
