# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Statistics::AdjustmentWorker, feature_category: :vulnerability_management do
  let(:worker) { described_class.new }

  describe "#perform" do
    let(:project_ids) { [1, 2, 3] }

    before do
      allow(Vulnerabilities::Statistics::AdjustmentService).to receive(:execute)
      allow(Vulnerabilities::HistoricalStatistics::AdjustmentService).to receive(:execute)
    end

    it 'calls `Vulnerabilities::Statistics::AdjustmentService` with given project_ids' do
      worker.perform(project_ids)

      expect(Vulnerabilities::Statistics::AdjustmentService).to have_received(:execute).with(project_ids)
    end

    it 'calls `Vulnerabilities::HistoricalStatistics::AdjustmentService` with given project_ids' do
      worker.perform(project_ids)

      expect(Vulnerabilities::HistoricalStatistics::AdjustmentService).to have_received(:execute).with(project_ids)
    end
  end
end
