# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PurgeStaleSecurityScans,
               :suppress_gitlab_schemas_validate_connection, schema: 20220407163559 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:builds) { table(:ci_builds) }
  let(:security_scans) { table(:security_scans) }
  let(:scanners) { table(:vulnerability_scanners) }

  let(:succeded_status) { 1 }
  let(:failed_status) { 2 }
  let(:purged_status) { 6 }

  let(:namespace) { namespaces.create!(name: 'foo', path: 'bar') }
  let(:project) { projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }
  let(:pipeline) { pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a', status: 'success') }
  let(:ci_build_1) { builds.create!(commit_id: pipeline.id, retried: false, type: 'Ci::Build', status: 'success') }
  let(:ci_build_2) { builds.create!(commit_id: pipeline.id, retried: false, type: 'Ci::Build', status: 'failed') }

  let!(:scanner) { scanners.create!(project_id: project.id, external_id: 'foo', name: 'Scanner', vendor: 'GitLab') }
  let!(:security_scan_1) { security_scans.create!(build_id: ci_build_1.id, scan_type: 1, status: succeded_status) }
  let!(:security_scan_2) { security_scans.create!(build_id: ci_build_2.id, scan_type: 1, status: failed_status) }
  let!(:security_scan_3) { security_scans.create!(build_id: ci_build_2.id, scan_type: 2) }

  describe '#perform' do
    subject(:migrate) { described_class.new.perform(security_scan_1.id, security_scan_2.id) }

    before do
      allow(::Gitlab::BackgroundMigration::Logger).to receive(:info)
    end

    it 'changes the status of the security_scan records and writes the log message' do
      expect { migrate }.to change { security_scan_1.reload.status }.from(succeded_status).to(purged_status)
                        .and not_change { security_scan_2.reload.status }.from(failed_status)

      expect(::Gitlab::BackgroundMigration::Logger).to have_received(:info).with(migrator: described_class.name,
                                                                                 message: 'Records have been updated',
                                                                                 updated_scans_count: 1)
    end
  end
end
