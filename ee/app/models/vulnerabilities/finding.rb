# frozen_string_literal: true

module Vulnerabilities
  class Finding < ApplicationRecord
    include ShaAttribute
    include ::Gitlab::Utils::StrongMemoize
    include Presentable
    include ::VulnerabilityFindingHelpers

    # https://gitlab.com/groups/gitlab-org/-/epics/3148
    # https://gitlab.com/gitlab-org/gitlab/-/issues/214563#note_370782508 is why the table names are not renamed
    self.table_name = "vulnerability_occurrences"

    FINDINGS_PER_PAGE = 20
    MAX_NUMBER_OF_IDENTIFIERS = 20

    paginates_per FINDINGS_PER_PAGE

    sha_attribute :project_fingerprint
    sha_attribute :location_fingerprint

    belongs_to :project, inverse_of: :vulnerability_findings
    belongs_to :scanner, class_name: 'Vulnerabilities::Scanner'
    belongs_to :primary_identifier, class_name: 'Vulnerabilities::Identifier', inverse_of: :primary_findings, foreign_key: 'primary_identifier_id'
    belongs_to :vulnerability, class_name: 'Vulnerability', inverse_of: :findings, foreign_key: 'vulnerability_id'

    has_many :finding_identifiers, class_name: 'Vulnerabilities::FindingIdentifier', inverse_of: :finding, foreign_key: 'occurrence_id'
    has_many :identifiers, through: :finding_identifiers, class_name: 'Vulnerabilities::Identifier'

    has_many :finding_links, class_name: 'Vulnerabilities::FindingLink', inverse_of: :finding, foreign_key: 'vulnerability_occurrence_id'

    has_many :finding_remediations, class_name: 'Vulnerabilities::FindingRemediation', inverse_of: :finding, foreign_key: 'vulnerability_occurrence_id'
    has_many :remediations, through: :finding_remediations

    has_many :finding_pipelines, class_name: 'Vulnerabilities::FindingPipeline', inverse_of: :finding, foreign_key: 'occurrence_id'
    has_many :pipelines, through: :finding_pipelines, class_name: 'Ci::Pipeline'

    has_many :signatures, class_name: 'Vulnerabilities::FindingSignature', inverse_of: :finding

    has_many :vulnerability_flags, class_name: 'Vulnerabilities::Flag', inverse_of: :finding, foreign_key: 'vulnerability_occurrence_id'

    has_one :evidence, class_name: 'Vulnerabilities::Finding::Evidence', inverse_of: :finding, foreign_key: 'vulnerability_occurrence_id'

    serialize :config_options, Serializers::Json # rubocop:disable Cop/ActiveRecordSerialize

    attr_writer :sha
    attr_accessor :scan

    enum confidence: ::Enums::Vulnerability.confidence_levels, _prefix: :confidence
    enum report_type: ::Enums::Vulnerability.report_types
    enum severity: ::Enums::Vulnerability.severity_levels, _prefix: :severity
    enum detection_method: ::Enums::Vulnerability.detection_methods

    validates :scanner, presence: true
    validates :project, presence: true
    validates :uuid, presence: true

    validates :primary_identifier, presence: true
    validates :project_fingerprint, presence: true
    validates :location_fingerprint, presence: true
    # Uniqueness validation doesn't work with binary columns, so save this useless query. It is enforce by DB constraint anyway.
    # TODO: find out why it fails
    # validates :location_fingerprint, presence: true, uniqueness: { scope: [:primary_identifier_id, :scanner_id, :ref, :pipeline_id, :project_id] }
    validates :name, presence: true
    validates :report_type, presence: true
    validates :severity, presence: true
    validates :confidence, presence: true
    validates :detection_method, presence: true

    validates :metadata_version, presence: true
    validates :raw_metadata, presence: true
    validates :details, json_schema: { filename: 'vulnerability_finding_details', draft: 7 }

    validates :description, length: { maximum: 15000 }
    validates :message, length: { maximum: 3000 }
    validates :solution, length: { maximum: 7000 }
    validates :cve, length: { maximum: 48400 }

    delegate :name, :external_id, to: :scanner, prefix: true, allow_nil: true

    scope :report_type, -> (type) { where(report_type: report_types[type]) }
    scope :ordered, -> { order(severity: :desc, confidence: :desc, id: :asc) }

    scope :by_report_types, -> (values) { where(report_type: values) }
    scope :by_projects, -> (values) { where(project_id: values) }
    scope :by_scanners, -> (values) { where(scanner_id: values) }
    scope :by_severities, -> (values) { where(severity: values) }
    scope :by_confidences, -> (values) { where(confidence: values) }
    scope :by_project_fingerprints, -> (values) { where(project_fingerprint: values) }

    scope :all_preloaded, -> do
      preload(:scanner, :identifiers, project: [:namespace, :project_feature])
    end

    scope :scoped_project, -> { where('vulnerability_occurrences.project_id = projects.id') }
    scope :eager_load_vulnerability_flags, -> { includes(:vulnerability_flags) }

    def self.for_pipelines_with_sha(pipelines)
      joins(:pipelines)
        .where(ci_pipelines: { id: pipelines })
        .select("vulnerability_occurrences.*, ci_pipelines.sha")
    end

    def self.for_pipelines(pipelines)
      joins(:finding_pipelines)
        .where(vulnerability_occurrence_pipelines: { pipeline_id: pipelines })
    end

    def self.counted_by_severity
      group(:severity).count.transform_keys do |severity|
        severities[severity]
      end
    end

    # sha can be sourced from a joined pipeline or set from the report
    def sha
      self[:sha] || @sha
    end

    def state
      return 'dismissed' if dismissal_feedback.present?

      if vulnerability.nil? || vulnerability.detected?
        'detected'
      elsif vulnerability.resolved?
        'resolved'
      elsif vulnerability.dismissed? # fail-safe check for cases when dismissal feedback was lost or was not created
        'dismissed'
      else
        'confirmed'
      end
    end

    def self.related_dismissal_feedback
      Feedback
      .where(arel_table[:report_type].eq(Feedback.arel_table[:category]))
      .where(arel_table[:project_id].eq(Feedback.arel_table[:project_id]))
      .where(Arel::Nodes::NamedFunction.new('ENCODE', [arel_table[:project_fingerprint], Arel::Nodes::SqlLiteral.new("'HEX'")]).eq(Feedback.arel_table[:project_fingerprint]))
      .for_dismissal
    end
    private_class_method :related_dismissal_feedback

    def self.dismissed
      where('EXISTS (?)', related_dismissal_feedback.select(1))
    end

    def self.undismissed
      where('NOT EXISTS (?)', related_dismissal_feedback.select(1))
    end

    def self.batch_count_by_project_and_severity(project_id, severity)
      BatchLoader.for(project_id: project_id, severity: severity).batch(default_value: 0) do |items, loader|
        project_ids = items.map { |i| i[:project_id] }.uniq
        severities = items.map { |i| i[:severity] }.uniq

        latest_pipelines = Ci::Pipeline
          .where(project_id: project_ids)
          .with_vulnerabilities
          .latest_successful_ids_per_project

        counts = for_pipelines(latest_pipelines)
          .undismissed
          .by_severities(severities)
          .group(:project_id, :severity)
          .count

        counts.each do |(found_project_id, found_severity), count|
          loader_key = { project_id: found_project_id, severity: found_severity }
          loader.call(loader_key, count)
        end
      end
    end

    def feedback(feedback_type:)
      load_feedback.find { |f| f.feedback_type == feedback_type }
    end

    def load_feedback
      BatchLoader.for(finding_key).batch(replace_methods: false) do |finding_keys, loader|
        project_ids = finding_keys.map { |key| key[:project_id] }
        categories = finding_keys.map { |key| key[:category] }
        fingerprints = finding_keys.map { |key| key[:project_fingerprint] }

        feedback = Vulnerabilities::Feedback.all_preloaded.where(
          project_id: project_ids.uniq,
          category: categories.uniq,
          project_fingerprint: fingerprints.uniq
        ).to_a

        finding_keys.each do |finding_key|
          loader.call(
            finding_key,
            feedback.select { |f| finding_key == f.finding_key }
          )
        end
      end
    end

    def dismissal_feedback
      feedback(feedback_type: 'dismissal')
    end

    def issue_feedback
      related_issues = vulnerability&.related_issues
      related_issues.blank? ? feedback(feedback_type: 'issue') : Vulnerabilities::Feedback.find_by(issue: related_issues)
    end

    def merge_request_feedback
      feedback(feedback_type: 'merge_request')
    end

    def metadata
      strong_memoize(:metadata) do
        data = Gitlab::Json.parse(raw_metadata)

        data = {} unless data.is_a?(Hash)

        data
      rescue JSON::ParserError
        {}
      end
    end

    def description
      super.presence || metadata.dig('description')
    end

    def solution
      super.presence || metadata.dig('solution') || remediations&.first&.dig('summary')
    end

    def location
      super.presence || metadata.fetch('location', {})
    end

    def file
      location.dig('file')
    end

    def links
      return metadata.fetch('links', []) if finding_links.load.empty?

      finding_links.as_json(only: [:name, :url])
    end

    def remediations
      return metadata.dig('remediations') unless super.present?

      super.as_json(only: [:summary], methods: [:diff])
    end

    def build_evidence_request(data)
      return if data.nil?

      {
        headers: data.fetch('headers', []).map do |request_header|
          {
            name: request_header['name'],
            value: request_header['value']
          }
        end,
        method: data['method'],
        url: data['url'],
        body: data['body']
      }
    end

    def build_evidence_response(data)
      return if data.nil?

      {
        headers: data.fetch('headers', []).map do |header_data|
          {
            name: header_data['name'],
            value: header_data['value']
          }
        end,
        status_code: data['status_code'],
        reason_phrase: data['reason_phrase'],
        body: data['body']
      }
    end

    def build_evidence_supporting_messages(data)
      return [] if data.nil?

      data.map do |message|
        {
          name: message['name'],
          request: build_evidence_request(message['request']),
          response: build_evidence_response(message['response'])
        }
      end
    end

    def build_evidence_source(data)
      return if data.nil?

      {
        id: data['id'],
        name: data['name'],
        url: data['url']
      }
    end

    def evidence
      {
        summary: metadata.dig('evidence', 'summary'),
        request: build_evidence_request(metadata.dig('evidence', 'request')),
        response: build_evidence_response(metadata.dig('evidence', 'response')),
        source: build_evidence_source(metadata.dig('evidence', 'source')),
        supporting_messages: build_evidence_supporting_messages(metadata.dig('evidence', 'supporting_messages'))
      }
    end

    def message
      super.presence || metadata.dig('message')
    end

    def cve_value
      cve || identifiers.find(&:cve?)&.name
    end

    def cwe_value
      identifiers.find(&:cwe?)&.name
    end

    def other_identifier_values
      identifiers.select(&:other?).map(&:name)
    end

    def assets
      metadata.fetch('assets', []).map do |asset_data|
        {
          name: asset_data['name'],
          type: asset_data['type'],
          url: asset_data['url']
        }
      end
    end

    alias_method :==, :eql?

    def eql?(other)
      return false unless other.is_a?(self.class)
      return false unless other.report_type == report_type && other.primary_identifier_fingerprint == primary_identifier_fingerprint

      if ::Feature.enabled?(:vulnerability_finding_tracking_signatures, project) && project.licensed_feature_available?(:vulnerability_finding_signatures)
        matches_signatures(other.signatures, other.uuid)
      else
        other.location_fingerprint == location_fingerprint
      end
    end

    # Array.difference (-) method uses hash and eql? methods to do comparison
    def hash
      # This is causing N+1 queries whenever we are calling findings, ActiveRecord uses #hash method to make sure the
      # array with findings is uniq before preloading. This method is used only in Gitlab::Ci::Reports::Security::VulnerabilityReportsComparer
      # where we are normalizing security report findings into instances of Vulnerabilities::Finding, this is why we are using original implementation
      # when Finding is persisted and identifiers are not preloaded.
      return super if persisted? && !identifiers.loaded?

      report_type.hash ^ location_fingerprint.hash ^ primary_identifier_fingerprint.hash
    end

    def severity_value
      self.class.severities[self.severity]
    end

    def confidence_value
      self.class.confidences[self.confidence]
    end

    # We will eventually have only UUIDv5 values for the `uuid`
    # attribute of the finding records.
    def uuid_v5
      if Gitlab::UUID.v5?(uuid)
        uuid
      else
        ::Security::VulnerabilityUUID.generate(
          report_type: report_type,
          primary_identifier_fingerprint: primary_identifier.fingerprint,
          location_fingerprint: location_fingerprint,
          project_id: project_id
        )
      end
    end

    def pipeline_branch
      pipelines&.last&.sha || project.default_branch
    end

    def false_positive?
      vulnerability_flags.false_positive.any?
    end

    protected

    def primary_identifier_fingerprint
      identifiers.first&.fingerprint
    end

    private

    def finding_key
      {
        project_id: project_id,
        category: report_type,
        project_fingerprint: project_fingerprint
      }
    end
  end
end
