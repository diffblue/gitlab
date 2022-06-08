# frozen_string_literal: true

module ManualQuarterlyCoTermBannerHelper
  def manual_quarterly_co_term_banner
    return unless current_user&.can_admin_all_resources?

    upcoming_reconciliation = GitlabSubscriptions::UpcomingReconciliation.next

    Gitlab::ManualQuarterlyCoTermBanner.new(upcoming_reconciliation)
  end
end
