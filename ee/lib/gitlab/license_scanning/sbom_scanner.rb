# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    # TODO: This class will be responsible for handling license scanning use
    # cases. It differentiates from ArtifactScanner based on its data source
    # i.e. it uses Sbom::Component objects instead of license scanning reports.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/384932 for more information.
    class SbomScanner < ::Gitlab::LicenseScanning::BaseScanner
      def self.latest_pipeline(project, ref)
        raise "Not implemented"
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
