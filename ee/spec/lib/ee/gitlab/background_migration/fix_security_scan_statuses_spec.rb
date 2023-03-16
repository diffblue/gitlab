# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixSecurityScanStatuses, feature_category: :vulnerability_management do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines, database: :ci) }
  let(:builds) { table(:ci_builds, database: :ci) { |model| model.primary_key = :id } }
  let(:security_scans) { table(:security_scans) }

  let(:namespace) { namespaces.create!(name: "foo", path: "bar") }
  let(:project) { projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }
  let(:normal_build_1) { create_build }
  let(:normal_build_2) { create_build }
  let(:expired_build) { create_build(artifacts_expire_at: 1.day.ago) }
  let(:failed_build) { create_build(status: 'failure') }
  let(:pipeline) do
    pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a', status: 'success', partition_id: 100)
  end

  let(:status_succeeded) { 1 }
  let(:status_job_failed) { 2 }
  let(:status_report_error) { 3 }
  let(:status_purged) { 6 }

  let!(:security_scan_1) { create_scan(normal_build_1, status_purged, info: { errors: [{ foo: :bar }] }) }
  let!(:security_scan_2) { create_scan(failed_build, status_purged) }
  let!(:security_scan_3) { create_scan(normal_build_2, status_purged) }
  let!(:security_scan_4) { create_scan(expired_build, status_purged) }

  let(:background_job) do
    described_class.new(
      start_id: security_scans.minimum(:id),
      end_id: security_scans.maximum(:id),
      batch_table: :security_scans,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  subject(:run_migration) { background_job.perform }

  describe '#perform' do
    before do
      allow(Gitlab::BackgroundMigration::Logger).to receive(:info)
    end

    it 'fixes the scan statuses' do
      expect { run_migration }
        .to change { security_scan_1.reload.status }.from(status_purged).to(status_report_error)
        .and change { security_scan_2.reload.status }.from(status_purged).to(status_job_failed)
        .and change { security_scan_3.reload.status }.from(status_purged).to(status_succeeded)
        .and not_change { security_scan_4.reload.status }.from(status_purged)

      expect(Gitlab::BackgroundMigration::Logger).to have_received(:info).exactly(3).times
    end
  end

  def create_scan(build, status, **extra_args)
    security_scans.create!(build_id: build.id, scan_type: 1, status: status, **extra_args)
  end

  def create_build(status: 'success', **extra_args)
    builds.create!(commit_id: pipeline.id,
                   retried: false,
                   status: status,
                   type: 'Ci::Build',
                   partition_id: 100,
                   **extra_args)
  end
end
