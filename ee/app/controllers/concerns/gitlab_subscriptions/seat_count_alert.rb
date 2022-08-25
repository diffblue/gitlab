# frozen_string_literal: true

module GitlabSubscriptions
  module SeatCountAlert
    def generate_seat_count_alert_data(namespace)
      return unless current_user && (root_ancestor = namespace&.root_ancestor)

      GitlabSubscriptions::Reconciliations::CalculateSeatCountDataService.new(
        namespace: root_ancestor,
        user: current_user
      ).execute
    end
  end
end
