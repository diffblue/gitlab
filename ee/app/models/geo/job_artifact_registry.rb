# frozen_string_literal: true

class Geo::JobArtifactRegistry < Geo::BaseRegistry
  include Geo::Syncable
  include ::Geo::ReplicableRegistry
  include ::Geo::VerifiableRegistry
  include IgnorableColumns

  MODEL_CLASS = ::Ci::JobArtifact
  MODEL_FOREIGN_KEY = :artifact_id

  ignore_column :success, remove_with: '15.6', remove_after: '2022-10-22'

  belongs_to :job_artifact, class_name: 'Ci::JobArtifact', foreign_key: :artifact_id

  # TODO: remove once `success` column has a default value set
  # https://gitlab.com/gitlab-org/gitlab/-/issues/214407
  def self.insert_for_model_ids(artifact_ids)
    records = artifact_ids.map do |artifact_id|
      new(artifact_id: artifact_id, success: false, created_at: Time.zone.now)
    end

    bulk_insert!(records, returns: :ids)
  end
end
