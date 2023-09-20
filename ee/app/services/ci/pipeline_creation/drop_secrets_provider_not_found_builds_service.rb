# frozen_string_literal: true

module Ci
  module PipelineCreation
    class DropSecretsProviderNotFoundBuildsService
      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute
        return if ::Feature.disabled?(:drop_job_on_secrets_provider_not_found, pipeline.project)
        return unless pipeline.project&.feature_available?(:ci_secrets_management)

        pipeline.builds.each do |build|
          next unless build.created?
          next unless build.secrets? && !build.secrets_provider?

          build.drop!(:secrets_provider_not_found, skip_pipeline_processing: true)
        end
      end

      private

      attr_reader :pipeline
    end
  end
end
