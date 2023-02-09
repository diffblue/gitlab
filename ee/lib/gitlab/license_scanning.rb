# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    def self.scanner_for_project(project, ref = project.default_branch)
      klass = scanner_class(project)
      pipeline = klass.latest_pipeline(project, ref)
      klass.new(project, pipeline)
    end

    def self.scanner_for_pipeline(project, pipeline)
      klass = scanner_class(project)
      klass.new(project, pipeline)
    end

    def self.scanner_class(project)
      return ::Gitlab::LicenseScanning::SbomScanner if Feature.enabled?(:license_scanning_sbom_scanner, project)

      ::Gitlab::LicenseScanning::ArtifactScanner
    end
  end
end
