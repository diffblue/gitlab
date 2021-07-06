# frozen_string_literal: true

module Vulnerabilities
  class Flag < ApplicationRecord
    self.table_name = 'vulnerability_flags'

    belongs_to :finding, class_name: 'Vulnerabilities::Finding', foreign_key: 'vulnerability_occurrence_id', inverse_of: :vulnerability_flags

    validates :origin, length: { maximum: 255 }
    validates :description, length: { maximum: 1024 }
    validates :flag_type, presence: true

    enum flag_type: {
      false_positive: 0
    }
  end
end
