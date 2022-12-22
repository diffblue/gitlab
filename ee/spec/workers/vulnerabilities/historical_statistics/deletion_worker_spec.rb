# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::HistoricalStatistics::DeletionWorker, feature_category: :vulnerability_management do
  let(:worker) { described_class.new }

  describe "#perform" do
    before do
      allow(Vulnerabilities::HistoricalStatistics::DeletionService).to receive(:execute)
    end

    it 'calls `Vulnerabilities::HistoricalStatistics::DeletionService`' do
      worker.perform

      expect(Vulnerabilities::HistoricalStatistics::DeletionService).to have_received(:execute).with(no_args)
    end
  end
end
