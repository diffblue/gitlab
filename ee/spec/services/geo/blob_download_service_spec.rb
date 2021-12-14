# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geo::BlobDownloadService do
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
          end

          context "when the file is missing on the primary" do
            context "when the feature flag geo_treat_missing_files_as_sync_failed is enabled" do
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
            end

            context "when the feature flag geo_treat_missing_files_as_sync_failed is disabled" do
              let(:result) { double(:result, success: false, primary_missing_file: true, bytes_downloaded: 123, reason: "foo", extra_details: nil) }

              before do
                stub_feature_flags(geo_treat_missing_files_as_sync_failed: false)
              end

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
          end
        end
      end
    end
  end
end
