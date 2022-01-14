# frozen_string_literal: true

module Vulnerabilities
  class Finding
    class Evidence < ApplicationRecord
      include IgnorableColumns
      self.table_name = 'vulnerability_finding_evidences'

      ignore_column :summary, remove_with: '14.9', remove_after: '2022-03-17'

      belongs_to :finding,
                 class_name: 'Vulnerabilities::Finding',
                 inverse_of: :finding_evidence,
                 foreign_key: 'vulnerability_occurrence_id',
                 optional: false

      validates :data, length: { maximum: 16_000_000 }, presence: true
    end
  end
end
