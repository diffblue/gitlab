# frozen_string_literal: true

module EE
  module Groups
    module SettingsHelper
      def delayed_project_removal_help_text
        if ::Gitlab::CurrentSettings.default_project_deletion_protection
          s_('DeletionSettings|Only administrators can delete projects.')
        else
          s_('DeletionSettings|Owners and administrators can delete projects.')
        end
      end

      def keep_deleted_option_label
        number = ::Gitlab::CurrentSettings.deletion_adjourned_period

        ns_("DeletionSettings|Keep deleted projects for %{number} day", "DeletionSettings|Keep deleted projects for %{number} days", number) % { number: number }
      end

      def saas_user_caps_help_text(group)
        user_cap_docs_link_url = help_page_path('user/group/manage', anchor: 'user-cap-for-groups')
        user_cap_docs_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: user_cap_docs_link_url }

        html_escape(saas_user_caps_i18n_string(group)) % { user_cap_docs_link_start: user_cap_docs_link_start, user_cap_docs_link_end: '</a>'.html_safe }
      end

      def delayed_deletion_disabled
        ::Gitlab::CurrentSettings.delayed_group_deletion == false
      end

      def unique_project_download_limit_settings_data
        settings = @group.namespace_settings || ::NamespaceSetting.new
        limit = settings.unique_project_download_limit
        interval = settings.unique_project_download_limit_interval_in_seconds
        allowlist = settings.unique_project_download_limit_allowlist
        alertlist = settings.unique_project_download_limit_alertlist
        auto_ban_users = settings.auto_ban_user_on_excessive_projects_download

        {
          group_full_path: @group.full_path,
          max_number_of_repository_downloads: limit,
          max_number_of_repository_downloads_within_time_period: interval,
          git_rate_limit_users_allowlist: allowlist,
          git_rate_limit_users_alertlist: alertlist,
          auto_ban_user_on_excessive_projects_download: auto_ban_users.to_s
        }
      end

      private

      def saas_user_caps_i18n_string(group)
        if ::Feature.enabled?(:saas_user_caps_auto_approve_pending_users_on_cap_increase, group.root_ancestor)
          s_('GroupSettings|When the number of active users exceeds this number, additional users must be %{user_cap_docs_link_start}approved by an owner%{user_cap_docs_link_end}. Leave empty if you don\'t want to enforce approvals.')
        else
          s_('GroupSettings|When the number of active users exceeds this number, additional users must be %{user_cap_docs_link_start}approved by an owner%{user_cap_docs_link_end}. Leave empty if you don\'t want to enforce approvals. Increasing the user cap will not automatically approve pending users.')
        end
      end
    end
  end
end
