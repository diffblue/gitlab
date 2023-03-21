# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class SbomScanner < ::Gitlab::LicenseScanning::BaseScanner
      include Gitlab::Utils::StrongMemoize

      def self.latest_pipeline(project, ref)
        project.latest_pipeline_with_reports_for_ref(ref, ::Ci::JobArtifact.of_report_type(:sbom))
      end

      def report
        return empty_report if pipeline.blank?

        components = PipelineComponents.new(pipeline: pipeline).fetch
        package_licenses = PackageLicenses.new(components: components).fetch

        ::Gitlab::Ci::Reports::LicenseScanning::Report.new.tap do |license_scanning_report|
          package_licenses.each do |package_license|
            package_license.licenses.each do |license_string|
              license = license_scanning_report.add_license(id: license_string, name: license_string)

              license.add_dependency(
                name: package_license.name,
                package_manager: package_license.package_manager,
                purl_type: package_license.purl_type,
                version: package_license.version
              )
            end
          end
        end
      end

      def has_data?
        return false if pipeline.blank?

        pipeline.has_reports?(::Ci::JobArtifact.of_report_type(:sbom))
      end

      def results_available?
        return false if pipeline.blank?

        pipeline.complete_and_has_reports?(::Ci::JobArtifact.of_report_type(:sbom))
      end

      def latest_build_for_default_branch
        pipeline = self.class.latest_pipeline(project, project.default_branch)

        return if pipeline.blank?

        pipeline.builds.latest.sbom_generation.last
      end
      strong_memoize_attr :latest_build_for_default_branch
    end
  end
end
