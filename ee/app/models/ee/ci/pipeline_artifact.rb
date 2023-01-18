# frozen_string_literal: true

module EE
  module Ci
    module PipelineArtifact
      extend ActiveSupport::Concern

      prepended do
        include ::Geo::ReplicableModel
        include ::Geo::VerifiableModel
        include ::Geo::VerificationStateDefinition

        with_replicator ::Geo::PipelineArtifactReplicator
      end

      class_methods do
        # Search for a list of projects associated, based on the query given in `query`.
        #
        # @param [String] query term that will search over projects :path, :name and :description
        #
        # @return [ActiveRecord::Relation<Ci::PipelineArtifact>] a collection of pipeline artifacts
        def search(query)
          return all if query.empty?

          where(project_id: ::Project.search(query).limit(1000).pluck_primary_key)
        end
      end
    end
  end
end
