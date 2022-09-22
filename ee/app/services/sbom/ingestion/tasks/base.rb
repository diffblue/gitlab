# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class Base
        def self.execute(pipeline, occurrence_maps)
          new(pipeline, occurrence_maps).execute
        end

        def initialize(pipeline, occurrence_maps)
          @pipeline = pipeline
          @occurrence_maps = occurrence_maps
        end

        def execute
          raise NoMethodError, "Implement the `execute` template method!"
        end

        private

        attr_reader :pipeline, :occurrence_maps
      end
    end
  end
end
