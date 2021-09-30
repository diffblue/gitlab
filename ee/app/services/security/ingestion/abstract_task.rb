# frozen_string_literal: true

module Security
  module Ingestion
    class AbstractTask
      def self.execute(pipeline, finding_maps)
        new(pipeline, finding_maps).execute
      end

      def initialize(pipeline, finding_maps)
        @pipeline = pipeline
        @finding_maps = finding_maps
      end

      def execute
        raise "Implement the `execute` template method!"
      end

      private

      attr_reader :pipeline, :finding_maps
    end
  end
end
