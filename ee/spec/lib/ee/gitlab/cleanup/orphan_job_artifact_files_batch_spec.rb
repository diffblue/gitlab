# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::OrphanJobArtifactFilesBatch, feature_category: :build_artifacts do
  include ::EE::GeoHelpers

  let(:batch_size) { 10 }
  let(:dry_run) { true }

  subject(:batch) { described_class.new(batch_size: batch_size, dry_run: dry_run) }

  context 'Geo secondary' do
    let(:max_artifact_id) { Ci::JobArtifact.maximum(:id).to_i }
    let(:orphan_id_1) { max_artifact_id + 1 }
    let(:orphan_id_2) { max_artifact_id + 2 }
    let!(:orphan_registry_1) { create(:geo_job_artifact_registry, artifact_id: orphan_id_1) }
    let!(:orphan_registry_2) { create(:geo_job_artifact_registry, artifact_id: orphan_id_2) }

    before do
      stub_secondary_node

      batch << "/tmp/foo/bar/#{orphan_id_1}"
      batch << "/tmp/foo/bar/#{orphan_id_2}"
    end

    context 'no dry run' do
      let(:dry_run) { false }

      it 'deletes registries for the found artifacts' do
        expect { batch.clean! }.to change { Geo::JobArtifactRegistry.count }.by(-2)
        expect(batch.geo_registries_count).to eq(2)
      end
    end

    context 'with dry run' do
      it 'does not remove registries' do
        create(:geo_job_artifact_registry)
        create(:geo_job_artifact_registry, :orphan)

        expect { batch.clean! }.not_to change { Geo::JobArtifactRegistry.count }
        expect(batch.geo_registries_count).to eq(2)
      end
    end
  end
end
