# frozen_string_literal: true

# This data migration causes resync of artifacts which are potentially missing
# due to https://gitlab.com/gitlab-org/gitlab/-/issues/419742.
#
# It's undesirable to resync unaffected artifacts due to wasted resources and
# money. For example, some customers have over 1 billion artifacts and
# petabytes of data. To re-transfer all of that data to potentially multiple
# secondary Geo sites is extremely costly. Therefore we should scope the
# resync as tightly as possible.
#
# Unfortunately it's not possible to programmatically determine which
# artifacts were synced by affected GitLab versions. Additionally, a migration
# which checks file existence of object stored artifacts is much more costly
# to run per artifact, and therefore a performant solution becomes much more
# complex and susceptible to failures. Geo is already capable of handling bulk
# resyncs without performance issues, so we should use a simple heuristic to
# scope the data migration even if it resyncs more artifacts than necessary.
#
# 2023-06-22: 16.1.0 was released. It is the first affected version.
# 2023-07-22: 16.2.0 was released. It is also affected.
# 2023-08-01: 16.1.3 was released with the fix.
# 2023-08-03: 16.2.3 was released with the fix.
#
# We know that 2023-06-22 is the earliest date that artifacts could be
# affected (ignoring pre-releases and development environments), so we can
# exclude all artifacts which were synced before that date.
#
# Without an upper bound, as time passes, this data migration would resync an
# increasing volume of artifacts for GitLab instances who are slow to upgrade,
# while the potential benefit of this data migration decreases. Also, it is
# common practice when upgrading to choose the latest available patch version.
#
# Therefore, there will very likely come a time after which all upgrades to
# 16.1 and 16.2 will be unaffected.
#
# We don't know what that time is, so we add a generous buffer after the date
# when 16.1 and 16.2 were both fixed and released. An upper bound of 2024-02-03
# has a buffer of 6 months.
#
# Summary:
#
# This post-deployment migration no-ops if object storage is not used for
# artifacts, or if Geo is not used to sync object storage. It enqueues a job for
# every batch of 10000 job artifact registry rows.
#
# Each job executes a SQL update query which is scoped to artifacts which were
# synced during the targeted time period.
class ResyncDirectUploadJobArtifactRegistry < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_geo
  disable_ddl_transaction!

  BATCH_SIZE = 10000
  REGISTRY_TABLE_NAME = 'job_artifact_registry'

  def up
    unless JobArtifactUploader.direct_upload_to_object_store?
      say "Skipping because job artifacts are not stored in object storage with direct upload"
      return
    end

    unless Gitlab::Geo.secondary?
      say "Skipping because this Geo site is not a secondary"
      return
    end

    unless Gitlab::Geo.current_node.sync_object_storage
      say "Skipping because this Geo site does not replicate object storage"
      return
    end

    say "Enqueuing Geo::ResyncDirectUploadJobArtifactRegistryWorker jobs to mark artifacts pending"
    say "See https://gitlab.com/gitlab-org/gitlab/-/issues/419742"

    job_count = 0

    each_batch_range(REGISTRY_TABLE_NAME, of: BATCH_SIZE) do |start, finish|
      if Rails.env.development? || Rails.env.test?
        say "Enqueuing Geo::ResyncDirectUploadJobArtifactRegistryWorker for range #{start}..#{finish}"
      end

      Geo::ResyncDirectUploadJobArtifactRegistryWorker.perform_async(start, finish)

      job_count += 1
    end

    say "Enqueued #{job_count} Geo::ResyncDirectUploadJobArtifactRegistryWorker #{'job'.pluralize(job_count)}"
  end

  def down
    # no-op
  end
end
