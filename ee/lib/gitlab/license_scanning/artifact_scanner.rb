# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class ArtifactScanner < ::Gitlab::LicenseScanning::BaseScanner
      include Gitlab::Utils::StrongMemoize

      def self.latest_pipeline(project, ref)
        project.latest_pipeline_with_reports_for_ref(ref, ::Ci::JobArtifact.of_report_type(:license_scanning))
      end

      def report
        pipeline.blank? ? empty_report : pipeline.license_scanning_report
      end

      def has_data?
        return false if pipeline.blank?

        pipeline.has_reports?(::Ci::JobArtifact.of_report_type(:license_scanning))
      end

      def results_available?
        return false if pipeline.blank?

        pipeline.complete_and_has_reports?(::Ci::JobArtifact.of_report_type(:license_scanning))
      end

      def latest_build_for_default_branch
        pipeline = self.class.latest_pipeline(project, project.default_branch)

        return if pipeline.blank?

        pipeline.builds.latest.license_scan.last
      end
      strong_memoize_attr :latest_build_for_default_branch
    end
  end
end
