# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    def self.scanner_for_project(project, ref = project.default_branch)
      sbom_pipeline = ::Gitlab::LicenseScanning::SbomScanner.latest_pipeline(project, ref)

      ::Gitlab::LicenseScanning::SbomScanner.new(project, sbom_pipeline)
    end

    def self.scanner_for_pipeline(project, pipeline)
      ::Gitlab::LicenseScanning::SbomScanner.new(project, pipeline)
    end
  end
end
