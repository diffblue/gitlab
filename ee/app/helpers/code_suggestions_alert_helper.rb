# frozen_string_literal: true

module CodeSuggestionsAlertHelper
  def show_code_suggestions_alert?
    return false unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
    return false if cookies[:code_suggestions_alert_dismissed] == 'true'
    return false if Feature.disabled?(:code_suggestions_alert, current_user)
    return true if current_user.blank? # check user is logged in
    return false unless new_nav_callout_hidden?

    !current_user.code_suggestions_enabled?
  end

  def new_nav_callout_hidden?
    user_dismissed_before?(::Users::CalloutsHelper::NEW_NAVIGATION_CALLOUT, 30.minutes.ago) ||
      gitlab_com_user_created_after_new_nav_rollout?
  end

  def show_code_suggestions_third_party_alert?(root_ancestor)
    current_user.present? &&
      ::Gitlab::CurrentSettings.should_check_namespace_plan? &&
      Feature.enabled?(:code_suggestions_third_party_alert, current_user) &&
      show_code_suggestions_third_party_callout? &&
      current_user.code_suggestions_enabled? &&
      root_ancestor.code_suggestions &&
      root_ancestor.third_party_ai_features_enabled
  end
end
