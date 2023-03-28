# frozen_string_literal: true

module Vulnerabilities
  class StateTransition < ApplicationRecord
    include BulkInsertSafe

    self.table_name = 'vulnerability_state_transitions'

    belongs_to :author, class_name: 'User', inverse_of: :vulnerability_state_transitions
    belongs_to :vulnerability, class_name: 'Vulnerability', inverse_of: :state_transitions
    belongs_to :pipeline, class_name: 'Ci::Pipeline',
      foreign_key: :state_changed_at_pipeline_id,
      inverse_of: :vulnerability_state_transitions
    validates :comment, length: { maximum: 50_000 }
    validates :vulnerability_id, :from_state, :to_state, presence: true
    validate :to_state_and_from_state_differ

    enum from_state: ::Enums::Vulnerability.vulnerability_states, _prefix: true
    enum to_state: ::Enums::Vulnerability.vulnerability_states, _prefix: true

    declarative_enum DismissalReasonEnum

    scope :by_to_states, ->(states) { where(to_state: states) }

    private

    def to_state_and_from_state_differ
      last_state_transition = self.class.where(vulnerability: vulnerability).where.not(id: id).last

      return unless to_state == from_state && last_state_transition&.dismissal_reason == dismissal_reason

      errors.add(:to_state, "must not be the same as from_state for the same dismissal_reason")
    end
  end
end
