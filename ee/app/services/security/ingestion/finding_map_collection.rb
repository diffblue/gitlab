# frozen_string_literal: true

module Security
  module Ingestion
    class FindingMapCollection
      include Enumerable

      def initialize(security_scan)
        @security_scan = security_scan
      end

      def each
        return to_enum(:each) unless block_given?

        deduplicated_findings.each do |security_finding|
          yield create_finding_map_for(security_finding)
        end
      end

      private

      attr_reader :security_scan

      delegate :findings, :report_findings, to: :security_scan, private: true

      def create_finding_map_for(security_finding)
        # For SAST findings, we override the finding UUID with an existing finding UUID
        # if we have a matching one.
        report_uuid = security_finding.overridden_uuid || security_finding.uuid

        FindingMap.new(security_finding, report_findings_map[report_uuid])
      end

      def report_findings_map
        @report_findings_map ||= report_findings.index_by(&:uuid)
      end

      # Sorting will make sure the findings with `overridden_uuid` values will be
      # processed before the others.
      # We are also sorting by `uuid` to prevent having deadlock errors while
      # ingesting the findings.
      def deduplicated_findings
        @deduplicated_findings ||= findings.deduplicated.sort do |a, b|
          [b.overridden_uuid.to_s, b.uuid] <=> [a.overridden_uuid.to_s, a.uuid]
        end
      end
    end
  end
end
