# frozen_string_literal: true

module LicenseMonitoringHelper
  include Gitlab::Utils::StrongMemoize

  def show_active_user_count_threshold_banner?
    return if ::Gitlab.com?
    return unless admin_section?
    return if user_dismissed?(Users::CalloutsHelper::ACTIVE_USER_COUNT_THRESHOLD)
    return if license_not_available_or_trial?

    current_user&.can_admin_all_resources? && current_license.active_user_count_threshold_reached?
  end

  def users_over_license
    strong_memoize(:users_over_license) do
      license_is_over_capacity? ? current_license_overage : 0
    end
  end

  private

  def license_is_over_capacity?
    return if ::Gitlab.com?
    return if license_not_available_or_trial?

    current_license_overage > 0
  end

  def license_not_available_or_trial?
    current_license.nil? || current_license.trial?
  end

  def current_license
    strong_memoize(:current_license) { License.current }
  end

  def current_license_overage
    strong_memoize(:current_license_overage) { current_license.overage_with_historical_max }
  end

  def active_user_count_threshold
    strong_memoize(:active_user_count_threshold) { current_license.active_user_count_threshold }
  end

  def total_user_count
    strong_memoize(:total_user_count) { current_license.restricted_user_count }
  end

  def remaining_user_count
    strong_memoize(:remaining_user_count) { current_license.remaining_user_count }
  end
end
