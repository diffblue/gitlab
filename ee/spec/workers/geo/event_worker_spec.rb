# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geo::EventWorker, :geo, feature_category: :geo_replication do
  describe "#perform" do
    it "calls Geo::EventService" do
      args = ["package_file", "created", { "model_record_id" => 1 }]
      service = double(:service)
      expect(service).to receive(:execute)
      expect(::Geo::EventService).to receive(:new).with(*args).and_return(service)

      described_class.new.perform(*args)
    end
  end
end
