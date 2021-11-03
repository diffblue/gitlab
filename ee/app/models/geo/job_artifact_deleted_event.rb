# frozen_string_literal: true

module Geo
  class JobArtifactDeletedEvent < ApplicationRecord
    include Geo::Model
    include Geo::Eventable
    include BulkInsertSafe

    belongs_to :job_artifact, class_name: 'Ci::JobArtifact'

    validates :job_artifact, :file_path, presence: true
  end
end
