# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geo::BatchEventCreateWorker, :geo, feature_category: :geo_replication do
  describe "#perform" do
    it "calls Gitlab::Geo::Replicator.bulk_create_events" do
      events = []

      expect(::Gitlab::Geo::Replicator).to receive(:bulk_create_events).with(events)

      described_class.new.perform(events)
    end
  end
end
