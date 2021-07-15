# frozen_string_literal: true

module Vulnerabilities
  class Finding
    class Evidence < ApplicationRecord
      self.table_name = 'vulnerability_finding_evidences'

      belongs_to :finding, class_name: 'Vulnerabilities::Finding', inverse_of: :evidence, foreign_key: 'vulnerability_occurrence_id', optional: false

      has_one :request, class_name: 'Vulnerabilities::Finding::Evidence::Request', inverse_of: :evidence, foreign_key: 'vulnerability_finding_evidence_id'
      has_one :response, class_name: 'Vulnerabilities::Finding::Evidence::Response', inverse_of: :evidence, foreign_key: 'vulnerability_finding_evidence_id'
      has_one :supporting_message, class_name: 'Vulnerabilities::Finding::Evidence::SupportingMessage', inverse_of: :evidence, foreign_key: 'vulnerability_finding_evidence_id'
      has_one :source, class_name: 'Vulnerabilities::Finding::Evidence::Source', inverse_of: :evidence, foreign_key: 'vulnerability_finding_evidence_id'
      has_many :assets, class_name: 'Vulnerabilities::Finding::Evidence::Asset', inverse_of: :evidence, foreign_key: 'vulnerability_finding_evidence_id'

      validates :summary, length: { maximum: 8_000_000 }
    end
  end
end
