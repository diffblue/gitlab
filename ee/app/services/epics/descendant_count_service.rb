# frozen_string_literal: true

module Epics
  class DescendantCountService
    include Gitlab::Utils::StrongMemoize

    attr_reader :epic, :current_user

    def initialize(epic, current_user)
      @epic = epic
      @current_user = current_user
    end

    def opened_epics
      epics_count.fetch(Epic.state_ids[:opened], 0)
    end

    def closed_epics
      epics_count.fetch(Epic.state_ids[:closed], 0)
    end

    def opened_issues
      opened_state_id = Issue.available_states[:opened]

      issues_count.fetch(opened_state_id, 0)
    end

    def closed_issues
      closed_state_id = Issue.available_states[:closed]

      issues_count.fetch(closed_state_id, 0)
    end

    def issues_on_track
      issue_health_statuses.fetch('on_track', 0)
    end

    def issues_needing_attention
      issue_health_statuses.fetch('needs_attention', 0)
    end

    def issues_at_risk
      issue_health_statuses.fetch('at_risk', 0)
    end

    private

    def epics_count
      strong_memoize(:epics_count) do
        accessible_epics.id_not_in(epic.id).counts_by_state
      end
    end

    def issues_count
      strong_memoize(:issue_counts) do
        Issue.in_epics(accessible_epics).counts_by_state
      end
    end

    def issue_health_statuses
      strong_memoize(:issue_health_statuses) do
        Issue.in_epics(accessible_epics)
          .opened
          .with_any_health_status
          .counts_by_health_status
      end
    end

    def accessible_epics
      strong_memoize(:epics) do
        epic.base_and_descendants
      end
    end
  end
end
