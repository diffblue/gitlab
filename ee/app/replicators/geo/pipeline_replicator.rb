# frozen_string_literal: true

module Geo
  class PipelineReplicator < Gitlab::Geo::Replicator
    event :pipeline_ref_created

    def self.model
      ::Ci::Pipeline
    end

    def log_geo_pipeline_ref_created_event
      return unless ::Gitlab::Geo.primary?

      publish(:pipeline_ref_created, **event_params)
    end

    def consume_event_pipeline_ref_created(**params)
      model_record.ensure_persistent_ref
    end
  end
end
