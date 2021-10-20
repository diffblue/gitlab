# frozen_string_literal: true

# This is a join model between the `Finding` and `Remediation` models.
module Vulnerabilities
  class FindingRemediation < ApplicationRecord
    self.table_name = 'vulnerability_findings_remediations'

    belongs_to :finding, class_name: 'Vulnerabilities::Finding', inverse_of: :finding_remediations, foreign_key: 'vulnerability_occurrence_id', optional: false
    belongs_to :remediation, class_name: 'Vulnerabilities::Remediation', inverse_of: :finding_remediations, foreign_key: 'vulnerability_remediation_id', optional: false

    scope :by_finding_id, -> (finding_ids) { where(vulnerability_occurrence_id: finding_ids) }
  end
end
