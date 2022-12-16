# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class BranchComponents
      def initialize(project:, branch_ref:)
        @pipeline = project.latest_pipeline_with_reports_for_ref(branch_ref, ::Ci::JobArtifact.of_report_type(:sbom))
      end

      def fetch
        return [] unless pipeline

        PipelineComponents.new(pipeline: pipeline).fetch
      end

      private

      attr_reader :pipeline
    end
  end
end
