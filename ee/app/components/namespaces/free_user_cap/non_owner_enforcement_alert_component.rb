# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class NonOwnerEnforcementAlertComponent < EnforcementAlertComponent
      private

      def render?
        return false unless ::Namespaces::FreeUserCap.non_owner_access?(user: user, namespace: namespace)

        breached_cap_limit?
      end

      def alert_attributes
        {
          title: alert_title,
          # see issue with ViewComponent overriding Kernel version
          # https://github.com/github/view_component/issues/156#issuecomment-737469885
          body: Kernel.format(
            _("To remove the %{link_start}read-only%{link_end} state and regain write access, " \
              "ask your top-level group owner(s) to reduce the number of users in your top-level group to " \
              "%{free_limit} users or less, or to upgrade to a paid tier which do not have " \
              "user limits."),
            link_start: free_user_limit_link_start,
            link_end: link_end,
            free_limit: free_user_limit
          ).html_safe
        }
      end
    end
  end
end
