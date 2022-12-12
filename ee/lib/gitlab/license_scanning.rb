# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    def self.scanner_for_project(project, ref = project.default_branch)
      klass = scanner_class
      pipeline = klass.latest_pipeline(project, ref)
      klass.new(project, pipeline)
    end

    def self.scanner_for_pipeline(pipeline)
      klass = scanner_class
      klass.new(pipeline.project, pipeline)
    end

    # TODO: return ::Gitlab::LicenseScanning::SbomScanner
    # or ::Gitlab::LicenseScanning::ArtifactScanner
    # based on feature flags, and implement fallback logic.
    # For more information see https://gitlab.com/gitlab-org/gitlab/-/issues/384935
    def self.scanner_class
      ::Gitlab::LicenseScanning::ArtifactScanner
    end
  end
end
