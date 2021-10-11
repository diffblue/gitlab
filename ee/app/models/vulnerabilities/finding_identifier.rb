# frozen_string_literal: true

module Vulnerabilities
  class FindingIdentifier < ApplicationRecord
    self.table_name = "vulnerability_occurrence_identifiers"

    alias_attribute :finding_id, :occurrence_id

    belongs_to :finding, class_name: 'Vulnerabilities::Finding', inverse_of: :finding_identifiers, foreign_key: 'occurrence_id'
    belongs_to :identifier, class_name: 'Vulnerabilities::Identifier', inverse_of: :finding_identifiers

    validates :finding, presence: true
    validates :identifier, presence: true
    validates :identifier_id, uniqueness: { scope: [:occurrence_id] }
  end
end
