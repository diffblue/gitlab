# frozen_string_literal: true

module Security
  class StoreGroupedScansService < ::BaseService
    include ::Gitlab::ExclusiveLeaseHelpers

    LEASE_TTL = 30.minutes
    LEASE_TRY_AFTER = 3.seconds
    LEASE_NAMESPACE = "store_grouped_scans"

    def self.execute(artifacts)
      new(artifacts).execute
    end

    def initialize(artifacts)
      @artifacts = artifacts
      @known_keys = Set.new
    end

    def execute
      in_lock(lease_key, ttl: LEASE_TTL, sleep_sec: LEASE_TRY_AFTER) do
        sorted_artifacts.reduce(false) do |deduplicate, artifact|
          store_scan_for(artifact, deduplicate)
        end
      end
    rescue Gitlab::Ci::Parsers::ParserError => error
      Gitlab::ErrorTracking.track_exception(error)
    end

    private

    attr_reader :artifacts, :known_keys

    def lease_key
      "#{LEASE_NAMESPACE}:#{pipeline_id}:#{report_type}"
    end

    def pipeline_id
      artifacts.first&.job&.pipeline_id
    end

    def report_type
      artifacts.first&.file_type
    end

    def sorted_artifacts
      @sorted_artifacts ||= artifacts.each { |artifact| prepare_report_for(artifact) }.sort do |a, b|
        report_a = a.security_report
        report_b = b.security_report

        report_a.primary_scanner_order_to(report_b)
      end
    end

    def prepare_report_for(artifact)
      artifact.security_report(validate: true)
    end

    def store_scan_for(artifact, deduplicate)
      StoreScanService.execute(artifact, known_keys, deduplicate)
    ensure
      artifact.clear_security_report
    end
  end
end
