# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ResyncDirectUploadJobArtifactRegistry, :geo, :sidekiq_inline, feature_category: :geo_replication do
  include EE::GeoHelpers

  let(:job_artifact_registry) { table(:job_artifact_registry) }

  describe '#up' do
    let(:synced_after) { DateTime.parse('2023-06-22T00:00:00') }
    let(:synced_before) { DateTime.parse('2024-02-03T00:00:00') }

    context 'when direct upload is enabled for job artifacts' do
      let(:options) { GitlabSettings::Options.build({ enabled: true, direct_upload: true }) }

      before do
        allow(JobArtifactUploader).to receive(:object_store_options).and_return(options)
      end

      context 'when the site is a Geo secondary' do
        let(:node) { instance_double('GeoNode', sync_object_storage: sync_object_storage) }

        before do
          allow(Gitlab::Geo).to receive(:secondary?).and_return(true)
          allow(Gitlab::Geo).to receive(:current_node).and_return(node)
        end

        context 'when sync_object_storage is enabled for the current Geo site' do
          let(:sync_object_storage) { true }

          context 'with job artifact registry rows' do
            it 'marks pending if synced between 2023-06-22 and 2024-02-03' do
              registry1 = job_artifact_registry.create!(artifact_id: 1, state: 2, last_synced_at: synced_after)
              registry2 = job_artifact_registry.create!(artifact_id: 2, state: 2, last_synced_at: synced_before)

              migrate!

              expect(registry1.reload.state).to eq(0)
              expect(registry2.reload.state).to eq(0)
            end

            it 'does not update if not synced' do
              started = job_artifact_registry.create!(artifact_id: 2, state: 1)
              failed = job_artifact_registry.create!(artifact_id: 3, state: 3)

              migrate!

              expect(started.reload.state).to eq(1)
              expect(failed.reload.state).to eq(3)
            end

            it 'does not update if synced before 2023-06-22' do
              too_early = job_artifact_registry.create!(
                artifact_id: 1, state: 2, last_synced_at: synced_after - 1.second)

              migrate!

              expect(too_early.reload.state).to eq(2)
            end

            it 'does not update if synced after 2024-02-03' do
              too_late = job_artifact_registry.create!(
                artifact_id: 1, state: 2, last_synced_at: synced_before + 1.second)

              migrate!

              expect(too_late.reload.state).to eq(2)
            end
          end
        end

        context 'when sync_object_storage is disabled for the current Geo site' do
          let(:sync_object_storage) { false }

          it 'does not update job artifact registry' do
            registry1 = job_artifact_registry.create!(artifact_id: 1, state: 2, last_synced_at: synced_after)
            registry2 = job_artifact_registry.create!(artifact_id: 2, state: 2, last_synced_at: synced_before)

            expect do
              migrate!
            end.to output(%r{Skipping because this Geo site does not replicate object storage}).to_stdout

            expect(registry1.reload.state).to eq(2)
            expect(registry2.reload.state).to eq(2)
          end
        end
      end

      context 'when the site is a Geo primary' do
        before do
          allow(Gitlab::Geo).to receive(:secondary?).and_return(false)
        end

        it 'does not update job artifact registry' do
          registry1 = job_artifact_registry.create!(artifact_id: 1, state: 2, last_synced_at: synced_after)
          registry2 = job_artifact_registry.create!(artifact_id: 2, state: 2, last_synced_at: synced_before)

          expect do
            migrate!
          end.to output(%r{Skipping because this Geo site is not a secondary}).to_stdout

          expect(registry1.reload.state).to eq(2)
          expect(registry2.reload.state).to eq(2)
        end
      end
    end

    context 'when direct upload is disabled for job artifacts' do
      let(:options) { GitlabSettings::Options.build({ enabled: true, direct_upload: false }) }

      before do
        allow(JobArtifactUploader).to receive(:object_store_options).and_return(options)
      end

      it 'does not update job artifact registry' do
        registry1 = job_artifact_registry.create!(artifact_id: 1, state: 2, last_synced_at: synced_after)
        registry2 = job_artifact_registry.create!(artifact_id: 2, state: 2, last_synced_at: synced_before)

        expect do
          migrate!
        end.to output(%r{Skipping because job artifacts are not stored in object storage with direct upload}).to_stdout

        expect(registry1.reload.state).to eq(2)
        expect(registry2.reload.state).to eq(2)
      end
    end

    context 'when object storage is disabled for job artifacts' do
      let(:options) { GitlabSettings::Options.build({ enabled: false, direct_upload: true }) }

      before do
        allow(JobArtifactUploader).to receive(:object_store_options).and_return(options)
      end

      it 'does not update job artifact registry' do
        registry1 = job_artifact_registry.create!(artifact_id: 1, state: 2, last_synced_at: synced_after)
        registry2 = job_artifact_registry.create!(artifact_id: 2, state: 2, last_synced_at: synced_before)

        expect do
          migrate!
        end.to output(%r{Skipping because job artifacts are not stored in object storage with direct upload}).to_stdout

        expect(registry1.reload.state).to eq(2)
        expect(registry2.reload.state).to eq(2)
      end
    end
  end
end
