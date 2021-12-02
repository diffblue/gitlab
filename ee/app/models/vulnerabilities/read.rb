# frozen_string_literal: true

module Vulnerabilities
  class Read < ApplicationRecord
    self.table_name = "vulnerability_reads"

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
    validates :has_issues, inclusion: { in: [true, false], message: _('must be a boolean value') }
    validates :resolved_on_default_branch, inclusion: { in: [true, false], message: _('must be a boolean value') }

    enum state: ::Enums::Vulnerability.vulnerability_states
    enum report_type: ::Enums::Vulnerability.report_types
    enum severity: ::Enums::Vulnerability.severity_levels, _prefix: :severity
  end
end
