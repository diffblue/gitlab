# frozen_string_literal: true

module Vulnerabilities
  class Read < ApplicationRecord
    include EachBatch
    include UnnestedInFilters::Dsl

    self.table_name = "vulnerability_reads"
    self.primary_key = :vulnerability_id

    belongs_to :vulnerability
    belongs_to :project
    belongs_to :scanner, class_name: 'Vulnerabilities::Scanner'

    validates :vulnerability_id, uniqueness: true, presence: true
    validates :project_id, presence: true
    validates :scanner_id, presence: true
    validates :report_type, presence: true
    validates :severity, presence: true
    validates :state, presence: true
    validates :uuid, uniqueness: { case_sensitive: false }, presence: true

    validates :location_image, length: { maximum: 2048 }
    validates :has_issues, inclusion: { in: [true, false], message: N_('must be a boolean value') }
    validates :resolved_on_default_branch, inclusion: { in: [true, false], message: N_('must be a boolean value') }

    enum state: ::Enums::Vulnerability.vulnerability_states
    enum report_type: ::Enums::Vulnerability.report_types
    enum severity: ::Enums::Vulnerability.severity_levels, _prefix: :severity

    scope :by_uuid, -> (uuids) { where(uuid: uuids) }

    scope :order_severity_asc, -> { reorder(severity: :asc, vulnerability_id: :desc) }
    scope :order_severity_desc, -> { reorder(severity: :desc, vulnerability_id: :desc) }
    scope :order_detected_at_asc, -> { reorder(vulnerability_id: :asc) }
    scope :order_detected_at_desc, -> { reorder(vulnerability_id: :desc) }

    scope :by_scanner, -> (scanner) { where(scanner: scanner) }
    scope :by_scanner_ids, -> (scanner_ids) { where(scanner_id: scanner_ids) }
    scope :for_projects, -> (project_ids) { where(project_id: project_ids) }
    scope :grouped_by_severity, -> { reorder(severity: :desc).group(:severity) }
    scope :with_report_types, -> (report_types) { where(report_type: report_types) }
    scope :with_severities, -> (severities) { where(severity: severities) }
    scope :with_states, -> (states) { where(state: states) }
    scope :with_container_image, -> (images) { where(location_image: images) }
    scope :with_cluster_agent_ids, -> (agent_ids) { where(cluster_agent_id: agent_ids) }
    scope :with_resolution, -> (has_resolution = true) { where(resolved_on_default_branch: has_resolution) }
    scope :with_issues, -> (has_issues = true) { where(has_issues: has_issues) }
    scope :with_scanner_external_ids, -> (scanner_external_ids) { joins(:scanner).merge(::Vulnerabilities::Scanner.with_external_id(scanner_external_ids)) }
    scope :with_findings_scanner_and_identifiers, -> { includes(vulnerability: { findings: [:scanner, :identifiers, finding_identifiers: :identifier] }) }
    scope :resolved_on_default_branch, -> { where('resolved_on_default_branch IS TRUE') }

    scope :as_vulnerabilities, -> do
      preload(vulnerability: { project: [:route] }).current_scope.tap do |relation|
        relation.define_singleton_method(:records) do
          super().map(&:vulnerability)
        end
      end
    end

    def self.order_by(method)
      case method.to_s
      when 'severity_desc' then order_severity_desc
      when 'severity_asc' then order_severity_asc
      when 'detected_desc' then order_detected_at_desc
      when 'detected_asc' then order_detected_at_asc
      else
        order_severity_desc
      end
    end

    def self.container_images
      # This method should be used only with pagination. When used without a specific limit, it might try to process an
      # unreasonable amount of records leading to a statement timeout.

      # We are enforcing keyset order here to make sure `primary_key` will not be automatically applied when returning
      # `ordered_items` from Gitlab::Graphql::Pagination::Keyset::Connection in GraphQL API. `distinct` option must be
      # set to true in `Gitlab::Pagination::Keyset::ColumnOrderDefinition` to return the collection in proper order.

      keyset_order = Gitlab::Pagination::Keyset::Order.build(
        [
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: :location_image,
            column_expression: arel_table[:location_image],
            order_expression: arel_table[:location_image].asc,
            distinct: true
          )
        ])

      where(report_type: [:container_scanning, :cluster_image_scanning])
        .where.not(location_image: nil)
        .reorder(keyset_order)
        .select(:location_image)
        .distinct
    end

    def self.fetch_uuids
      pluck(:uuid)
    end
  end
end
