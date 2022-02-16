# frozen_string_literal: true

class Geo::JobArtifactRegistry < Geo::BaseRegistry
  include Geo::Syncable
  include ::Geo::ReplicableRegistry
  include ::Geo::VerifiableRegistry

  MODEL_CLASS = ::Ci::JobArtifact
  MODEL_FOREIGN_KEY = :artifact_id

  belongs_to :job_artifact, class_name: 'Ci::JobArtifact', foreign_key: :artifact_id

  # When false, RegistryConsistencyService will frequently check the end of the
  # table to quickly handle new replicables.
  def self.has_create_events?
    ::Geo::JobArtifactReplicator.enabled?
  end

  # TODO: remove once `success` column has a default value set
  # https://gitlab.com/gitlab-org/gitlab/-/issues/214407
  def self.insert_for_model_ids(artifact_ids)
    records = artifact_ids.map do |artifact_id|
      new(artifact_id: artifact_id, success: false, created_at: Time.zone.now)
    end

    bulk_insert!(records, returns: :ids)
  end

  def self.delete_for_model_ids(artifact_ids)
    artifact_ids.map do |artifact_id|
      delete_worker_class.perform_async(:job_artifact, artifact_id)
    end
  end

  def self.delete_worker_class
    ::Geo::FileRegistryRemovalWorker
  end

  # TODO Remove this when enabling geo_job_artifact_replication by default
  override :registry_consistency_worker_enabled?
  def self.registry_consistency_worker_enabled?
    true
  end

  def self.failed
    if ::Geo::JobArtifactReplicator.enabled?
      with_state(:failed)
    else
      where(success: false).where.not(retry_count: nil)
    end
  end

  def self.never_attempted_sync
    if ::Geo::JobArtifactReplicator.enabled?
      pending.where(last_synced_at: nil)
    else
      where(success: false, retry_count: nil)
    end
  end

  def self.retry_due
    if ::Geo::JobArtifactReplicator.enabled?
      where(arel_table[:retry_at].eq(nil).or(arel_table[:retry_at].lt(Time.current)))
    else
      where('retry_at is NULL OR retry_at < ?', Time.current)
    end
  end

  def self.synced
    if ::Geo::JobArtifactReplicator.enabled?
      with_state(:synced).or(where(success: true))
    else
      where(success: true)
    end
  end
end
