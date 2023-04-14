# frozen_string_literal: true

module Security
  module Ingestion
    # Service for starting the ingestion of the security reports
    # into the database.
    class IngestReportsService
      def self.execute(pipeline)
        new(pipeline).execute
      end

      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute
        store_reports
        mark_resolved_vulnerabilities
        mark_project_as_vulnerable!
        set_latest_pipeline!
        schedule_mark_dropped_vulnerabilities
        schedule_auto_fix
      end

      private

      attr_reader :pipeline

      delegate :project, to: :pipeline, private: true

      def store_reports
        latest_security_scans.flat_map do |scan|
          ingest(scan).then { |ingested_ids| collect_ingested_ids_for(scan, ingested_ids) }
        end
      end

      def collect_ingested_ids_for(scan, ingested_ids)
        scan.scanners.each do |scanner|
          ingested_ids_by_scanner[scanner] += ingested_ids
        end
      end

      def latest_security_scans
        @latest_security_scans ||= pipeline.security_scans.without_errors.latest
      end

      def ingested_ids_by_scanner
        @ingested_ids_by_scanner ||= Hash.new { [] }
      end

      def ingest(security_scan)
        IngestReportService.execute(security_scan)
      end

      def mark_project_as_vulnerable!
        project.project_setting.update!(has_vulnerabilities: true)
      end

      def set_latest_pipeline!
        Vulnerabilities::Statistic.set_latest_pipeline_with(pipeline)
      end

      def mark_resolved_vulnerabilities
        ingested_ids_by_scanner.each do |scanner, ingested_ids|
          MarkAsResolvedService.execute(scanner, ingested_ids)
        end
      end

      def schedule_mark_dropped_vulnerabilities
        primary_identifiers_by_scan_type.each do |scan_type, identifiers|
          ScheduleMarkDroppedAsResolvedService.execute(pipeline.project_id, scan_type, identifiers)
        end
      end

      def primary_identifiers_by_scan_type
        latest_security_scans.group_by(&:scan_type)
                             .transform_values { |scans| scans.flat_map(&:report_primary_identifiers).compact }
      end

      def schedule_auto_fix
        ::Security::AutoFixWorker.perform_async(pipeline.id) if auto_fix_enabled?
      end

      def auto_fix_enabled?
        project.security_setting&.auto_fix_enabled? && has_auto_fixable_report_type?
      end

      def has_auto_fixable_report_type?
        (project.security_setting.auto_fix_enabled_types & report_types).any?
      end

      def report_types
        latest_security_scans.map(&:scan_type).map(&:to_sym)
      end
    end
  end
end
