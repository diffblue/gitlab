# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class NonOwnerNotificationAlertComponent < NotificationAlertComponent
      private

      def render?
        return false unless ::Namespaces::FreeUserCap.non_owner_access?(user: user, namespace: namespace)

        breached_cap_limit?
      end

      def alert_attributes
        {
          title: Kernel.format(
            _(
              'Your top-level group %{namespace_name} will move to a read-only state soon'
            ),
            namespace_name: namespace.name,
            free_user_limit: free_user_limit
          ).html_safe,
          body: Kernel.format(
            _(
              'The top-level group, including any subgroups and projects, will be placed into a ' \
              '%{link_start}read-only%{link_end} state soon. To retain write access, ask your ' \
              'top-level group Owner to %{reduce_link_start}reduce the number of users%{link_end} to ' \
              '%{free_user_limit} or less. An Owner of the top-level group can also start a ' \
              'free trial or upgrade to a paid tier, which do not have user limits. ' \
              'The Owners of the top-level group have also been notified.'
            ),
            free_user_limit: free_user_limit,
            link_start: read_only_namespaces_link_start,
            reduce_link_start: "<a href='#{manage_members_path}' target='_blank' rel='noopener noreferrer'>".html_safe,
            link_end: link_end
          ).html_safe
        }
      end

      def manage_members_path
        help_page_path('user/free_user_limit', anchor: 'manage-members-in-your-namespace')
      end
    end
  end
end
