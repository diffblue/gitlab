# frozen_string_literal: true

module CodeSuggestionsAlertHelper
  def show_code_suggestions_alert?
    return false unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
    return false if cookies[:code_suggestions_alert_dismissed] == 'true'
    return false if Feature.disabled?(:code_suggestions_alert, current_user)
    return true if current_user.blank? # check user is logged in
    return false unless user_dismissed_before?(::Users::CalloutsHelper::NEW_NAVIGATION_CALLOUT, 30.minutes.ago)

    !current_user.code_suggestions_enabled?
  end
end
