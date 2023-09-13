# frozen_string_literal: true

module PackageMetadata
  class AdvisoryScanService
    def self.execute(advisory)
      ::Gitlab::VulnerabilityScanning::AdvisoryScanner.scan_projects_for(advisory)
    end
  end
end
