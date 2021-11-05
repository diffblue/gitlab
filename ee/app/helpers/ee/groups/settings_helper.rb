# frozen_string_literal: true

module EE
  module Groups
    module SettingsHelper
      def delayed_project_removal_help_text
        html_escape(delayed_project_removal_i18n_string) % {
          waiting_period: ::Gitlab::CurrentSettings.deletion_adjourned_period,
          link_start: '<a href="%{url}">'.html_safe % { url: general_admin_application_settings_path(anchor: 'js-visibility-settings') },
          link_end: '</a>'.html_safe
        }
      end

      private

      def delayed_project_removal_i18n_string
        if current_user&.can_admin_all_resources?
          s_('GroupSettings|Projects will be permanently deleted after a %{waiting_period}-day delay. This delay can be %{link_start}customized by an admin%{link_end} in instance settings. Inherited by subgroups.')
        else
          s_('GroupSettings|Projects will be permanently deleted after a %{waiting_period}-day delay. Inherited by subgroups.')
        end
      end
    end
  end
end
