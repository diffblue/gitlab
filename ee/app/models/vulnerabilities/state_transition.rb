# frozen_string_literal: true

module Vulnerabilities
  class StateTransition < ApplicationRecord
    self.table_name = 'vulnerability_state_transitions'

    belongs_to :author, class_name: 'User', inverse_of: :vulnerability_state_transitions
    belongs_to :vulnerability
    validates :vulnerability_id, :from_state, :to_state, presence: true

    enum from_state: ::Enums::Vulnerability.vulnerability_states, _prefix: true
    enum to_state: ::Enums::Vulnerability.vulnerability_states, _prefix: true
  end
end
