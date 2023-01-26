# frozen_string_literal: true

module Vulnerabilities
  class StateTransition < ApplicationRecord
    include BulkInsertSafe

    self.table_name = 'vulnerability_state_transitions'

    belongs_to :author, class_name: 'User', inverse_of: :vulnerability_state_transitions
    belongs_to :vulnerability, class_name: 'Vulnerability', inverse_of: :state_transitions
    validates :comment, length: { maximum: 50_000 }
    validates :vulnerability_id, :from_state, :to_state, presence: true
    validate :to_state_and_from_state_differ

    scope :latest_for_vulnerability, -> do
      latest_state_transition = ::Vulnerability
        .select("latest_state_transition.*")
        .joins(<<~SQL)
          JOIN LATERAL (
            SELECT * FROM vulnerability_state_transitions
            WHERE vulnerability_id = vulnerabilities.id
            ORDER BY created_at DESC
            LIMIT 1
          ) AS latest_state_transition ON TRUE
        SQL

      from(latest_state_transition, "vulnerability_state_transitions")
    end

    enum from_state: ::Enums::Vulnerability.vulnerability_states, _prefix: true
    enum to_state: ::Enums::Vulnerability.vulnerability_states, _prefix: true

    scope :by_to_states, ->(states) { where(to_state: states) }

    private

    def to_state_and_from_state_differ
      errors.add(:to_state, "must not be the same as from_state") if to_state == from_state
    end
  end
end
