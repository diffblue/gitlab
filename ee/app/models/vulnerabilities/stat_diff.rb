# frozen_string_literal: true

module Vulnerabilities
  class StatDiff
    def initialize(vulnerability)
      self.vulnerability = vulnerability
    end

    def changed_attributes
      update_required? ? changes.keys : []
    end

    def changed_values
      update_required? ? changes.values : []
    end

    def changes
      @changes ||= total_change.merge(severity_changes)
    end

    def update_required?
      severity_changes.present?
    end

    delegate :project_id, to: :vulnerability

    private

    delegate :active_states, :passive_states, to: Vulnerability, private: true
    delegate :destroyed?, to: :vulnerability, prefix: true, private: true
    delegate :state, :severity, :state_previous_change, :severity_previous_change,
      :severity_previously_changed?, :state_previously_changed?,
      to: :vulnerability, private: true

    attr_accessor :vulnerability

    def total_change
      { 'total' => severity_changes.values.sum }
    end

    def severity_changes
      @severity_changes ||= previous_severity_value.merge(current_severity_value)
    end

    def previous_severity_value
      decrease_previous_severity? ? { previous_severity => -1 } : {}
    end

    def current_severity_value
      if decrease_current_severity?
        { severity => -1 }
      elsif increment_current_severity?
        { severity => 1 }
      else
        {}
      end
    end

    def decrease_previous_severity?
      previous_severity && (state_moved_to_passive? || state_remained_active?)
    end

    def decrease_current_severity?
      vulnerability_destroyed? || (!severity_previously_changed? && state_moved_to_passive?)
    end

    def increment_current_severity?
      (severity_previously_changed? && state.in?(active_states)) || state_moved_to_active?
    end

    def state_moved_to_passive?
      previous_state.in?(active_states) && state.in?(passive_states)
    end

    def state_moved_to_active?
      previous_state.in?(passive_states) && state.in?(active_states)
    end

    def state_remained_active?
      state.in?(active_states) && (!state_previously_changed? || previous_state.in?(active_states))
    end

    def previous_state
      state_previous_change&.first
    end

    def previous_severity
      severity_previous_change&.first
    end
  end
end
