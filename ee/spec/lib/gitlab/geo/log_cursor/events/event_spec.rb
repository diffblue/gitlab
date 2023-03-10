# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Geo::LogCursor::Events::Event,
  :clean_gitlab_redis_shared_state,
  feature_category: :geo_replication do
  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:event) { create(:geo_event, :package_file, event_name: "created") }
  let(:event_log) { create(:geo_event_log, geo_event: event) }
  let(:replicable) { Packages::PackageFile.find(event.payload["model_record_id"]) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

  subject { described_class.new(event, Time.now, logger) }

  describe "#process" do
    it "enqueues Geo::EventWorker" do
      expect(::Geo::EventWorker).to receive(:perform_async).with(
        "package_file",
        "created",
        { "model_record_id" => replicable.id }
      )

      subject.process
    end

    it "eventually calls Replicator#consume", :sidekiq_inline do
      expect_next_instance_of(::Geo::PackageFileReplicator) do |replicator|
        expect(replicator).to receive(:consume).with(
          :created,
          { model_record_id: replicable.id }
        )
      end

      subject.process
    end
  end
end
