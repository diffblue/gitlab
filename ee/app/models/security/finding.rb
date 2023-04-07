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
    include EachBatch
    include Presentable
    include PartitionedTable

    MAX_PARTITION_SIZE = 100.gigabyte
    ATTRIBUTES_DELEGATED_TO_FINDING_DATA = %i[name description solution location identifiers links false_positive?
                                              assets evidence details remediation_byte_offsets
                                              raw_source_code_extract].freeze

    self.table_name = 'security_findings'
    self.primary_key = :id # As ActiveRecord does not support compound PKs

    attr_readonly :partition_number

    partitioned_by :partition_number,
                   strategy: :sliding_list,
                   next_partition_if: -> (partition) { partition_full?(partition) },
                   detach_partition_if: -> (partition) { detach_partition?(partition.value) }

    belongs_to :scan, inverse_of: :findings, optional: false
    belongs_to :scanner, class_name: 'Vulnerabilities::Scanner', inverse_of: :security_findings, optional: false

    belongs_to :vulnerability_finding,
               class_name: 'Vulnerabilities::Finding',
               primary_key: :uuid,
               foreign_key: :uuid,
               inverse_of: :security_findings

    has_one :build, through: :scan, disable_joins: true
    has_one :vulnerability, through: :vulnerability_finding

    has_many :state_transitions, through: :vulnerability
    has_many :issue_links, through: :vulnerability
    has_many :merge_request_links, through: :vulnerability

    has_many :feedbacks,
             class_name: 'Vulnerabilities::Feedback',
             inverse_of: :security_finding,
             primary_key: 'uuid',
             foreign_key: 'finding_uuid'

    enum confidence: ::Enums::Vulnerability.confidence_levels, _prefix: :confidence
    enum severity: ::Enums::Vulnerability.severity_levels, _prefix: :severity

    validates :uuid, presence: true
    validates :finding_data, json_schema: { filename: "security_finding_data" }

    scope :by_uuid, -> (uuids) { where(uuid: uuids) }
    scope :by_build_ids, -> (build_ids) { joins(:scan).merge(Security::Scan.by_build_ids(build_ids)) }
    scope :by_project_fingerprints, -> (fingerprints) { where(project_fingerprint: fingerprints) }
    scope :by_severity_levels, -> (severity_levels) { where(severity: severity_levels) }
    scope :by_confidence_levels, -> (confidence_levels) { where(confidence: confidence_levels) }
    scope :by_report_types, -> (report_types) { joins(:scan).merge(Scan.by_scan_types(report_types)) }
    scope :by_scan, -> (scans) { where(scan: scans) }
    scope :by_scanners, -> (scanners) { where(scanner: scanners) }
    scope :by_state, -> (states, check_feedback: false) do
      states = Array(states).map(&:to_s)

      relation = where('EXISTS (?)',
                       Vulnerability.select(1)
                                    .with_states(states)
                                    .joins(:findings)
                                    .where('vulnerability_occurrences.uuid = security_findings.uuid::text'))

      # If the given states includes `dismissed` and `check_feedback` is true,
      # we need to check `vulnerabilities_feedback` as well.
      relation = relation.or(dismissed_by_feedback) if check_feedback && states.include?('dismissed')

      # If the given list of states includes `detected` we should return
      # the findings which does not exist on main branch as well.
      relation = relation.or(recently_detected) if states.include?('detected')

      relation
    end

    scope :dismissed_by_feedback, -> do
      where('EXISTS (?)',
            Scan.select(1)
                .has_dismissal_feedback
                .where('security_scans.id = security_findings.scan_id')
                .where('vulnerability_feedback.finding_uuid = security_findings.uuid'))
    end

    scope :recently_detected, -> do
      where('NOT EXISTS (?)',
            Vulnerabilities::Finding.select(1)
                                    .where('vulnerability_occurrences.uuid = security_findings.uuid::text'))
    end

    scope :undismissed_by_vulnerability, -> do
      where('NOT EXISTS (?)',
            Vulnerability.select(1)
                         .dismissed
                         .joins(:findings)
                         .where('vulnerability_occurrences.uuid = security_findings.uuid::text'))
    end

    scope :undismissed, -> do
      where('NOT EXISTS (?)',
            Scan.select(1)
                .has_dismissal_feedback
                .where('security_scans.id = security_findings.scan_id')
                .where('vulnerability_feedback.finding_uuid = security_findings.uuid'))
    end

    scope :ordered, -> { order(severity: :desc, id: :asc) }
    scope :with_pipeline_entities, -> { preload(build: [:job_artifacts, :pipeline]) }
    scope :with_scan, -> { preload(:scan) }
    scope :with_scanner, -> { includes(:scanner) }
    scope :with_feedbacks, -> { includes(:feedbacks) }
    scope :with_vulnerability, -> { includes(:vulnerability) }
    scope :with_state_transitions, -> { with_vulnerability.includes(:state_transitions) }
    scope :with_issue_links, -> { with_vulnerability.includes(:issue_links) }
    scope :with_merge_request_links, -> { with_vulnerability.includes(:merge_request_links) }
    scope :deduplicated, -> { where(deduplicated: true) }
    scope :grouped_by_scan_type, -> { joins(:scan).group('security_scans.scan_type') }

    delegate :scan_type, :pipeline, :remediations_proxy, to: :scan, allow_nil: true
    delegate :project, :sha, to: :pipeline

    class << self
      def count_by_scan_type
        grouped_by_scan_type.count
      end

      def latest_by_uuid(uuid)
        by_uuid(uuid).order(scan_id: :desc).first
      end

      def partition_full?(partition)
        partition.data_size >= MAX_PARTITION_SIZE
      end

      def detach_partition?(partition_number)
        last_finding_in_partition(partition_number)&.scan&.findings_can_be_purged?
      end

      # It is possible that this logic gets called before the `security_findings` table
      # becomes partitioned, therefore, we return the default column value if there is no partition yet.
      def active_partition_number
        active_partition&.value || column_defaults['partition_number']
      end

      def fetch_uuids
        pluck(:uuid)
      end

      private

      delegate :active_partition, to: :partitioning_strategy, private: true

      def last_finding_in_partition(partition_number)
        where(partition_number: partition_number).last
      end
    end

    # Following alias attributes as used by `Vulnerabilities::FindingEntity`
    alias_attribute :raw_metadata, :finding_data
    alias_attribute :report_type, :scan_type

    def dismissal_feedback
      feedbacks.find(&:for_dismissal?)
    end

    def issue_feedback
      feedbacks.find(&:for_issue?)
    end

    def merge_request_feedback
      feedbacks.find(&:for_merge_request?)
    end

    def state
      return vulnerability.state if vulnerability

      dismissal_feedback ? 'dismissed' : 'detected'
    end

    # Symbolizing the hash keys is important as Grape entity
    # works with symbolized keys only.
    # See https://github.com/ruby-grape/grape-entity/issues/223
    def symbolized_finding_data
      @symbolized_finding_data ||= finding_data.deep_symbolize_keys
    end

    def finding_data=(value)
      super
    ensure
      @symbolized_finding_data = nil
    end

    # Defines methods for the keys exist in `finding_data` to support the same
    # interface with `Vulnerabilities::Finding` model as these methods are used
    # by `Vulnerabilities::FindingEntity`.
    ATTRIBUTES_DELEGATED_TO_FINDING_DATA.each do |delegated_attribute|
      define_method(delegated_attribute) do
        symbolized_finding_data.fetch(delegated_attribute)
      end
    end

    def remediations
      return [] unless symbolized_finding_data[:remediation_byte_offsets]

      symbolized_finding_data[:remediation_byte_offsets].map { |offset| offset.values_at(:start_byte, :end_byte) }
                                                        .then { remediations_proxy.by_byte_offsets(_1) }
    end

    def finding_details
      finding_data['details']
    end
  end
end
