# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ResyncDirectUploadJobArtifactRegistryWorker, :geo, feature_category: :geo_replication do
  include MigrationsHelpers
  include EE::GeoHelpers

  subject(:job) { described_class.new }

  let(:job_artifact_registry) { table(:job_artifact_registry) }
  let(:synced_after) { DateTime.parse('2023-06-22T00:00:00') }
  let(:synced_before) { DateTime.parse('2024-02-03T00:00:00') }

  it 'uses a Geo queue' do
    expect(job.sidekiq_options_hash).to include(
      'queue_namespace' => :geo
    )
  end

  describe '#perform' do
    context 'with job artifact registry rows' do
      it 'marks pending if synced between 2023-06-22 and 2024-02-03' do
        registry1 = job_artifact_registry.create!(artifact_id: 1, state: 2, last_synced_at: synced_after)
        registry2 = job_artifact_registry.create!(artifact_id: 2, state: 2, last_synced_at: synced_after)
        registry3 = job_artifact_registry.create!(artifact_id: 3, state: 2, last_synced_at: synced_before)
        registry4 = job_artifact_registry.create!(artifact_id: 4, state: 2, last_synced_at: synced_before)

        job.perform(registry2.id, registry3.id)

        expect(registry1.reload.state).to eq(2)
        expect(registry2.reload.state).to eq(0)
        expect(registry3.reload.state).to eq(0)
        expect(registry4.reload.state).to eq(2)
      end

      it 'does not update if not synced' do
        started = job_artifact_registry.create!(artifact_id: 2, state: 1)
        failed = job_artifact_registry.create!(artifact_id: 3, state: 3)

        job.perform(started.id, failed.id)

        expect(started.reload.state).to eq(1)
        expect(failed.reload.state).to eq(3)
      end

      it 'does not update if synced before 2023-06-22' do
        too_early = job_artifact_registry.create!(
          artifact_id: 1, state: 2, last_synced_at: synced_after - 1.second)

        job.perform(too_early.id, too_early.id)

        expect(too_early.reload.state).to eq(2)
      end

      it 'does not update if synced after 2024-02-03' do
        too_late = job_artifact_registry.create!(
          artifact_id: 1, state: 2, last_synced_at: synced_before + 1.second)

        job.perform(too_late.id, too_late.id)

        expect(too_late.reload.state).to eq(2)
      end
    end
  end
end
