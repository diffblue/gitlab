# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class EnforcementAtLimitAlertComponent < BaseAlertComponent
      private

      ENFORCEMENT_AT_LIMIT_ALERT = 'enforcement_at_limit_alert'

      def breached_cap_limit?
        ::Namespaces::FreeUserCap::Enforcement.new(namespace).at_limit?
      end

      def feature_name
        ENFORCEMENT_AT_LIMIT_ALERT
      end

      def alert_attributes
        {
          # see issue with ViewComponent overriding Kernel version
          # https://github.com/github/view_component/issues/156#issuecomment-737469885
          title: Kernel.format(
            _("Your top-level group %{namespace_name} has reached the %{free_limit} user limit"),
            free_limit: free_user_limit,
            namespace_name: namespace.name
          ).html_safe,
          body: Kernel.format(
            n_("To invite more users, you can reduce the number of users in your " \
               "top-level group to %{free_limit} user or less. You can also upgrade to " \
               "a paid tier which do not have user limits. If you need additional " \
               "time, you can start a free 30-day trial which includes unlimited users.",
               "To invite more users, you can reduce the number of users in your " \
               "top-level group to %{free_limit} users or less. You can also upgrade to " \
               "a paid tier which do not have user limits. If you need additional " \
               "time, you can start a free 30-day trial which includes unlimited users.",
              free_user_limit
            ),
            free_limit: free_user_limit
          ).html_safe,
          primary_cta: namespace_primary_cta,
          secondary_cta: namespace_secondary_cta
        }
      end
    end
  end
end
