# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geo::BlobDownloadService, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  let(:model_record) { create(:package_file, :npm) }
  let(:replicator) { model_record.replicator }
  let(:registry_class) { replicator.registry_class }

  subject { described_class.new(replicator: replicator) }

  before do
    stub_current_geo_node(secondary)
  end

  describe "#execute" do
    let(:downloader) { double(:downloader) }

    before do
      expect(downloader).to receive(:execute).and_return(result)
      expect(::Gitlab::Geo::Replication::BlobDownloader).to receive(:new).and_return(downloader)
    end

    context "when it can obtain the exclusive lease" do
      context "when the registry record does not exist" do
        context "when the downloader returns success" do
          let(:result) { double(:result, success: true, primary_missing_file: false, bytes_downloaded: 123, reason: nil, extra_details: nil) }

          it "creates the registry" do
            expect do
              subject.execute
            end.to change { registry_class.count }.by(1)
          end

          it "sets sync state to synced" do
            subject.execute

            expect(registry_class.last).to be_synced
          end
        end

        context "when the downloader returns failure" do
          context "when the file is not missing on the primary" do
            let(:result) { double(:result, success: false, primary_missing_file: false, bytes_downloaded: 123, reason: "foo", extra_details: nil) }

            it "creates the registry" do
              expect do
                subject.execute
              end.to change { registry_class.count }.by(1)
            end

            it "sets sync state to failed" do
              subject.execute

              expect(registry_class.last).to be_failed
            end

            it 'caps retry wait time to 1 hour' do
              registry = replicator.registry
              registry.retry_count = 9999
              registry.save!

              subject.execute

              expect(registry.reload.retry_at).to be_within(10.minutes).of(1.hour.from_now)
            end
          end

          context "when the file is missing on the primary" do
            let(:result) { double(:result, success: false, primary_missing_file: true, bytes_downloaded: 123, reason: "foo", extra_details: nil) }

            it "creates the registry" do
              expect do
                subject.execute
              end.to change { registry_class.count }.by(1)
            end

            it "sets sync state to failed" do
              subject.execute

              expect(registry_class.last).to be_failed
            end

            it 'caps retry wait time to 4 hours' do
              registry = replicator.registry
              registry.retry_count = 9999
              registry.save!

              subject.execute

              expect(registry.reload.retry_at).to be_within(10.minutes).of(4.hours.from_now)
            end
          end
        end
      end
    end
  end
end
