# frozen_string_literal: true

class Geo::JobArtifactRegistry < Geo::BaseRegistry
  include ::Geo::ReplicableRegistry
  include ::Geo::VerifiableRegistry
  include IgnorableColumns

  MODEL_CLASS = ::Ci::JobArtifact
  MODEL_FOREIGN_KEY = :artifact_id

  ignore_column :success, remove_with: '15.8', remove_after: '2022-12-22'

  belongs_to :job_artifact, class_name: 'Ci::JobArtifact', foreign_key: :artifact_id
end
