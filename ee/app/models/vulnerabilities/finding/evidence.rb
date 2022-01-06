# frozen_string_literal: true

module Vulnerabilities
  class Finding
    class Evidence < ApplicationRecord
      self.table_name = 'vulnerability_finding_evidences'

      belongs_to :finding,
                 class_name: 'Vulnerabilities::Finding',
                 inverse_of: :finding_evidence,
                 foreign_key: 'vulnerability_occurrence_id',
                 optional: false

      validates :data, length: { maximum: 16_000_000 }, presence: true
    end
  end
end
