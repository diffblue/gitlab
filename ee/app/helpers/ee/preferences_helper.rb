# frozen_string_literal: true

module EE
  module PreferencesHelper
    extend ::Gitlab::Utils::Override

    override :excluded_dashboard_choices
    def excluded_dashboard_choices
      return [] if can?(current_user, :read_operations_dashboard)

      super
    end

    def group_view_choices
      strong_memoize(:group_view_choices) do
        choices = []
        choices << [_('Details (default)'), :details]
        choices << [_('Security dashboard'), :security_dashboard] if group_view_security_dashboard_enabled?
        choices
      end
    end

    def group_overview_content_preference?
      group_view_choices.size > 1
    end

    def should_show_code_suggestions_preferences?(user)
      ::Feature.enabled?(:enable_hamilton_in_user_preferences, user)
    end

    private

    def group_view_security_dashboard_enabled?
      License.feature_available?(:security_dashboard)
    end
  end
end
