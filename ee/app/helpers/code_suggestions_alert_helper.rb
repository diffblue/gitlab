# frozen_string_literal: true

module CodeSuggestionsAlertHelper
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
