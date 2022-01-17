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

      def saas_user_caps_help_text(group)
        user_cap_docs_link_url = help_page_path('user/group/index', anchor: 'user-cap-for-groups')
        user_cap_docs_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: user_cap_docs_link_url }

        html_escape(saas_user_caps_i18n_string(group)) % { user_cap_docs_link_start: user_cap_docs_link_start, user_cap_docs_link_end: '</a>'.html_safe }
      end

      private

      def delayed_project_removal_i18n_string
        if current_user&.can_admin_all_resources?
          s_('GroupSettings|Projects will be permanently deleted after a %{waiting_period}-day delay. This delay can be %{link_start}customized by an admin%{link_end} in instance settings. Inherited by subgroups.')
        else
          s_('GroupSettings|Projects will be permanently deleted after a %{waiting_period}-day delay. Inherited by subgroups.')
        end
      end

      def saas_user_caps_i18n_string(group)
        if ::Feature.enabled?(:saas_user_caps_auto_approve_pending_users_on_cap_increase, group.root_ancestor, default_enabled: :yaml)
          s_('GroupSettings|When the number of active users exceeds this number, additional users must be %{user_cap_docs_link_start}approved by an owner%{user_cap_docs_link_end}. Leave empty if you don\'t want to enforce approvals.')
        else
          s_('GroupSettings|When the number of active users exceeds this number, additional users must be %{user_cap_docs_link_start}approved by an owner%{user_cap_docs_link_end}. Leave empty if you don\'t want to enforce approvals. Increasing the user cap will not automatically approve pending users.')
        end
      end
    end
  end
end
