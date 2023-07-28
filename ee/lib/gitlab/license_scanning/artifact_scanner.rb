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

      def add_licenses(dependencies)
        report.licenses.each do |license|
          apply_license(license, dependencies)
        end

        dependencies
      end

      private

      def apply_license(license, dependencies)
        dependencies.each do |component|
          next unless license_includes_component?(license, component)
          next if component[:licenses].find { |license_hash| license_hash[:name] == license.name }

          component[:licenses].push(name: license.name, url: license.url)
        end
      end

      def license_includes_component?(license, component)
        license.dependencies.find do |license_dependency|
          # TODO: normalization doesn't currently do anything because license scanning reports
          # do not have a purl_type value.
          # See https://gitlab.com/gitlab-org/security/gitlab/-/issues/921 for more details.
          dependency_name = ::Sbom::PackageUrl::Normalizer.new(
            type: license_dependency.purl_type, text: component[:name]).normalize_name

          license_dependency.name == dependency_name
        end
      end
    end
  end
end
