# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    def self.scanner_for_project(project, ref = project.default_branch)
      artifact_pipeline = ::Gitlab::LicenseScanning::ArtifactScanner.latest_pipeline(project, ref)

      return ::Gitlab::LicenseScanning::ArtifactScanner.new(project, artifact_pipeline) unless Feature.enabled?(
        :license_scanning_sbom_scanner, project)

      sbom_pipeline = ::Gitlab::LicenseScanning::SbomScanner.latest_pipeline(project, ref)

      # If the SBoM pipeline is newer than the artifact
      # pipeline, then we use it instead since it has the
      # latest license information. We determine which is
      # newer by comparing their ids.
      if sbom_pipeline&.id.to_i > artifact_pipeline&.id.to_i
        ::Gitlab::LicenseScanning::SbomScanner.new(project, sbom_pipeline)
      else
        ::Gitlab::LicenseScanning::ArtifactScanner.new(project, artifact_pipeline)
      end
    end

    def self.scanner_for_pipeline(project, pipeline)
      artifact_scanner = ::Gitlab::LicenseScanning::ArtifactScanner.new(project, pipeline)

      return artifact_scanner unless Feature.enabled?(:license_scanning_sbom_scanner, project)

      return artifact_scanner if artifact_scanner.has_data?

      ::Gitlab::LicenseScanning::SbomScanner.new(project, pipeline)
    end
  end
end
