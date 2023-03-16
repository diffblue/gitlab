# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::SidekiqCronConfigWorker, feature_category: :geo_replication do
  describe '#perform' do
    it 'runs the cron manager' do
      manager = double('cron_manager')
      allow(Gitlab::Geo::CronManager).to receive(:new) { manager }

      expect(manager).to receive(:execute)

      described_class.new.perform
    end
  end
end
