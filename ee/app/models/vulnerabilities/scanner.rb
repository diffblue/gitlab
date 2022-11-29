# frozen_string_literal: true

module Vulnerabilities
  class Scanner < ApplicationRecord
    self.table_name = "vulnerability_scanners"

    attr_accessor :scan_type

    has_many :findings, class_name: 'Vulnerabilities::Finding', inverse_of: :scanner
    has_many :security_findings, class_name: 'Security::Finding', inverse_of: :scanner

    belongs_to :project

    validates :project, presence: true
    validates :external_id, presence: true, uniqueness: { scope: :project_id }
    validates :name, presence: true
    validates :vendor, length: { maximum: 255, allow_nil: false }

    scope :with_external_id, -> (external_ids) { where(external_id: external_ids) }

    scope :for_projects, -> (project_ids) { where(project_id: project_ids) }
    scope :with_report_type, -> do
      lateral = Vulnerabilities::Finding.where(Vulnerabilities::Finding.arel_table[:scanner_id].eq(arel_table[:id])).select(:report_type).limit(1)

      joins("JOIN LATERAL (#{lateral.to_sql}) report_types ON true")
        .select('DISTINCT ON ("vulnerability_scanners"."external_id", "report_types"."report_type") "vulnerability_scanners".*, "report_types"."report_type" AS "report_type"')
        .order('"vulnerability_scanners"."external_id" ASC, "report_types"."report_type" ASC')
    end

    def report_type
      self[:report_type] || scan_type
    end
  end
end
