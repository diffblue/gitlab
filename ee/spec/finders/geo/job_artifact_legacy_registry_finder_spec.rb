# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::JobArtifactLegacyRegistryFinder, :geo do
  it_behaves_like 'a file registry finder' do
    before do
      stub_artifacts_object_storage

      stub_feature_flags(geo_job_artifact_replication: false)
    end

    let_it_be(:project) { create(:project) }

    let_it_be(:replicable_1) { create(:ci_job_artifact, project: project) }
    let_it_be(:replicable_2) { create(:ci_job_artifact, project: project) }
    let_it_be(:replicable_3) { create(:ci_job_artifact, project: project) }
    let_it_be(:replicable_4) { create(:ci_job_artifact, project: project) }
    let_it_be(:replicable_5) { create(:ci_job_artifact, project: project) }
    let!(:replicable_6) { create(:ci_job_artifact, :remote_store, project: project) }
    let!(:replicable_7) { create(:ci_job_artifact, :remote_store, project: project) }
    let!(:replicable_8) { create(:ci_job_artifact, :remote_store, project: project) }

    let_it_be(:registry_1) { create(:geo_job_artifact_registry_legacy, :failed, artifact_id: replicable_1.id) }
    let_it_be(:registry_2) { create(:geo_job_artifact_registry_legacy, artifact_id: replicable_2.id, missing_on_primary: true) }
    let_it_be(:registry_3) { create(:geo_job_artifact_registry_legacy, :never_synced, artifact_id: replicable_3.id) }
    let_it_be(:registry_4) { create(:geo_job_artifact_registry_legacy, :failed, artifact_id: replicable_4.id) }
    let_it_be(:registry_5) { create(:geo_job_artifact_registry_legacy, artifact_id: replicable_5.id, missing_on_primary: true, retry_at: 1.day.ago) }
    let!(:registry_6) { create(:geo_job_artifact_registry_legacy, :failed, artifact_id: replicable_6.id) }
    let!(:registry_7) { create(:geo_job_artifact_registry_legacy, :failed, artifact_id: replicable_7.id, missing_on_primary: true) }
    let!(:registry_8) { create(:geo_job_artifact_registry_legacy, :never_synced, artifact_id: replicable_8.id) }
  end
end
