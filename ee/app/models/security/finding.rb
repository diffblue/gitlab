# frozen_string_literal: true

# This model represents the vulnerability findings
# discovered for all pipelines to use in pipeline
# security tab.
#
# Unlike `Vulnerabilities::Finding` model, this one
# only stores some important meta information to
# calculate which report artifact to download and parse.
module Security
  class Finding < ApplicationRecord
    include IgnorableColumns
    include EachBatch

    self.table_name = 'security_findings'

    ignore_column :position, remove_with: '14.8', remove_after: '2022-02-22'

    belongs_to :scan, inverse_of: :findings, optional: false
    belongs_to :scanner, class_name: 'Vulnerabilities::Scanner', inverse_of: :security_findings, optional: false

    has_one :build, through: :scan, disable_joins: true

    enum confidence: ::Enums::Vulnerability.confidence_levels, _prefix: :confidence
    enum severity: ::Enums::Vulnerability.severity_levels, _prefix: :severity

    validates :uuid, presence: true

    scope :by_uuid, -> (uuids) { where(uuid: uuids) }
    scope :by_build_ids, -> (build_ids) { joins(:scan).merge(Security::Scan.by_build_ids(build_ids)) }
    scope :by_project_fingerprints, -> (fingerprints) { where(project_fingerprint: fingerprints) }
    scope :by_severity_levels, -> (severity_levels) { where(severity: severity_levels) }
    scope :by_confidence_levels, -> (confidence_levels) { where(confidence: confidence_levels) }
    scope :by_report_types, -> (report_types) { joins(:scan).merge(Scan.by_scan_types(report_types)) }
    scope :undismissed, -> do
      where('NOT EXISTS (?)',
            Scan.select(1)
                .has_dismissal_feedback
                .where('security_scans.id = security_findings.scan_id')
                .where('vulnerability_feedback.project_fingerprint = security_findings.project_fingerprint'))
    end
    scope :latest, -> { joins(:scan).merge(Security::Scan.latest_successful) }
    scope :ordered, -> { order(severity: :desc, confidence: :desc, id: :asc) }
    scope :with_pipeline_entities, -> { preload(build: [:job_artifacts, :pipeline]) }
    scope :with_scan, -> { includes(:scan) }
    scope :with_scanner, -> { includes(:scanner) }
    scope :deduplicated, -> { where(deduplicated: true) }
    scope :grouped_by_scan_type, -> { joins(:scan).group('security_scans.scan_type') }

    delegate :scan_type, to: :scan, allow_nil: true

    def self.count_by_scan_type
      grouped_by_scan_type.count
    end
  end
end
