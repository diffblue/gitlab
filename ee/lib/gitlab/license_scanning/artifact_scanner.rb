# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class ArtifactScanner < ::Gitlab::LicenseScanning::BaseScanner
      def self.latest_pipeline(project, ref)
        project.latest_pipeline_with_reports_for_ref(ref, ::Ci::JobArtifact.of_report_type(:license_scanning))
      end

      def report
        pipeline.blank? ? empty_report : pipeline.license_scanning_report
      end

      def has_data?
        return false if pipeline.blank?

        pipeline.batch_lookup_report_artifact_for_file_type(:license_scanning).present?
      end

      def results_available?
        return false if pipeline.blank?

        pipeline.complete_and_has_reports?(::Ci::JobArtifact.of_report_type(:license_scanning))
      end

      private

      def empty_report
        ::Gitlab::Ci::Reports::LicenseScanning::Report.new
      end
    end
  end
end
