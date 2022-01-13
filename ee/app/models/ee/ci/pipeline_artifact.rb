# frozen_string_literal: true

module EE
  module Ci
    module PipelineArtifact
      extend ActiveSupport::Concern

      prepended do
        include ::Geo::ReplicableModel
        include ::Geo::VerifiableModel

        with_replicator ::Geo::PipelineArtifactReplicator
      end
    end
  end
end
