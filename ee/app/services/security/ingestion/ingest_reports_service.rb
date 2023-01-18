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
        mark_project_as_vulnerable!
        set_latest_pipeline!
        schedule_mark_dropped_vulnerabilities
        schedule_auto_fix
      end

      private

      attr_reader :pipeline

      delegate :project, to: :pipeline, private: true

      def store_reports
        latest_security_scans
          .flat_map { |scan| ingest(scan) }
          .then { |ids| mark_resolved_vulnerabilities(ids) }
      end

      def latest_security_scans
        @latest_security_scans ||= pipeline.security_scans.without_errors.latest
      end

      def ingest(security_scan)
        IngestReportService.execute(security_scan)
      end

      def mark_resolved_vulnerabilities(existing_ids)
        MarkAsResolvedService.execute(project, existing_ids)
      end

      def mark_project_as_vulnerable!
        project.project_setting.update!(has_vulnerabilities: true)
      end

      def set_latest_pipeline!
        Vulnerabilities::Statistic.set_latest_pipeline_with(pipeline)
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
