# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class ArtifactScanner < ::Gitlab::LicenseScanning::BaseScanner
      def self.latest_pipeline(project, ref)
        project.latest_pipeline_with_reports_for_ref(ref, ::Ci::JobArtifact.of_report_type(:license_scanning))
      end

      def report
        raise "Not implemented"
      end

      def has_data?
        raise "Not implemented"
      end

      def results_available?
        raise "Not implemented"
      end
    end
  end
end
