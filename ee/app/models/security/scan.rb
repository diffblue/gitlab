# frozen_string_literal: true

module Security
  class Scan < ApplicationRecord
    include CreatedAtFilterable

    STALE_AFTER = 90.days

    self.table_name = 'security_scans'

    validates :build_id, presence: true
    validates :scan_type, presence: true
    validates :info, json_schema: { filename: 'security_scan_info', draft: 7 }

    belongs_to :build, class_name: 'Ci::Build'
    belongs_to :project
    belongs_to :pipeline, class_name: 'Ci::Pipeline'

    has_many :findings, inverse_of: :scan

    enum scan_type: {
      sast: 1,
      dependency_scanning: 2,
      container_scanning: 3,
      dast: 4,
      secret_detection: 5,
      coverage_fuzzing: 6,
      api_fuzzing: 7,
      cluster_image_scanning: 8
    }

    declarative_enum Security::ScanStatusEnum

    scope :by_scan_types, -> (scan_types) { where(scan_type: sanitize_scan_types(scan_types)) }
    scope :by_project, -> (project) { where(project: project) }
    scope :distinct_scan_types, -> { select(:scan_type).distinct.pluck(:scan_type) }
    scope :scoped_project, -> { where('security_scans.project_id = projects.id') }

    scope :has_dismissal_feedback, -> do
      # The `category` enum on `vulnerability_feedback` table starts from 0 but the `scan_type` enum
      # on `security_scans` from 1. For this reason, we have to decrease the value of `scan_type` by one
      # to match with category values on `vulnerability_feedback` table.
      joins(project: :vulnerability_feedback)
        .where('vulnerability_feedback.category = (security_scans.scan_type - 1)')
        .merge(Vulnerabilities::Feedback.for_dismissal)
    end

    scope :latest, -> { where(latest: true) }
    scope :latest_successful, -> { latest.succeeded }
    scope :by_build_ids, ->(build_ids) { where(build_id: build_ids) }
    scope :without_errors, -> { where("jsonb_array_length(COALESCE(info->'errors', '[]'::jsonb)) = 0") }
    scope :stale, -> { where("created_at < ?", STALE_AFTER.ago).where.not(status: :purged) }
    scope :ordered_by_created_at_and_id, -> { order(:created_at, :id) }
    scope :with_warnings, -> { where("jsonb_array_length(COALESCE(info->'warnings', '[]'::jsonb)) > 0") }
    scope :with_errors, -> { where("jsonb_array_length(COALESCE(info->'errors', '[]'::jsonb)) > 0") }

    delegate :name, to: :build
    alias_attribute :type, :scan_type

    before_save :ensure_project_id_pipeline_id

    def self.sanitize_scan_types(given_types)
      scan_types.keys & Array(given_types).map(&:to_s)
    end

    def self.pipeline_ids(project, scan_type)
      by_scan_types(scan_type).by_project(project).succeeded.pluck(:pipeline_id)
    end

    # If the record is created 3 months ago and purged,
    # it means that all the previous records must be purged
    # as well so the related findings can be dropped.
    def findings_can_be_purged?
      created_at < STALE_AFTER.ago && purged?
    end

    def has_warnings?
      processing_warnings.present?
    end

    def processing_warnings
      info.fetch('warnings', [])
    end

    def processing_warnings=(warnings)
      info['warnings'] = warnings
    end

    def has_errors?
      processing_errors.present?
    end

    def processing_errors
      info.fetch('errors', [])
    end

    def processing_errors=(errors)
      info['errors'] = errors
    end

    def add_processing_error!(error)
      info['errors'] = processing_errors.push(error.stringify_keys)

      save!
    end

    # Returns the findings from the source report
    def report_findings
      @report_findings ||= security_report&.findings.to_a
    end

    def report_primary_identifiers
      @report_primary_identifiers ||= security_report&.primary_identifiers
    end

    def remediations_proxy
      @remediations_proxy ||= RemediationsProxy.new(job_artifact&.file)
    end

    def scanners
      external_ids = security_report.scanners.keys
      project.vulnerability_scanners.with_external_id(external_ids)
    end

    private

    def security_report
      job_artifact&.security_report
    end

    def primary_scanner
      security_report&.primary_scanner
    end

    def job_artifact
      build.job_artifacts.find_by_file_type(scan_type)
    end

    def ensure_project_id_pipeline_id
      self.project_id ||= build.project_id
      self.pipeline_id ||= build.commit_id
    end
  end
end
