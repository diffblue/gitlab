# frozen_string_literal: true

module Vulnerabilities
  class FindingLink < ApplicationRecord
    self.table_name = 'vulnerability_finding_links'

    belongs_to :finding, class_name: 'Vulnerabilities::Finding', inverse_of: :finding_links, foreign_key: 'vulnerability_occurrence_id'

    validates :finding, presence: true
    validates :url, presence: true, length: { maximum: 2048 }
    validates :name, length: { maximum: 255 }

    scope :by_finding_id, -> (finding_ids) { where(vulnerability_occurrence_id: finding_ids) }
  end
end
