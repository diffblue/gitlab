# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClearSharedRunnersMinutesWorker, feature_category: :continuous_integration do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform }

    before do
      [2, 3, 4, 5, 7, 8, 10, 14].each do |id|
        create(:namespace, id: id)
      end
    end

    context 'with batch size lower than count of namespaces' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 3)
      end

      it 'runs a worker per batch', :aggregate_failures do
        # Spreads evenly accross 8 hours (28,800 seconds)
        expect(Ci::BatchResetMinutesWorker).to receive(:perform_in).with(0.seconds, 2, 4)
        expect(Ci::BatchResetMinutesWorker).to receive(:perform_in).with(7200.seconds, 5, 7)
        expect(Ci::BatchResetMinutesWorker).to receive(:perform_in).with(14400.seconds, 8, 10)
        expect(Ci::BatchResetMinutesWorker).to receive(:perform_in).with(21600.seconds, 11, 13)
        expect(Ci::BatchResetMinutesWorker).to receive(:perform_in).with(28800.seconds, 14, 16)

        subject
      end
    end

    context 'with batch size higher than count of namespaces' do
      # Uses default BATCH_SIZE
      it 'runs the worker in a single batch', :aggregate_failures do
        # Runs a single batch, immediately
        expect(Ci::BatchResetMinutesWorker).to receive(:perform_in).with(0.seconds, 2, 100001)

        subject
      end
    end
  end
end
