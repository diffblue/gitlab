# frozen_string_literal: true

# Remove with https://gitlab.com/gitlab-org/gitlab/-/issues/375607
module Namespaces
  module FreeUserCap
    class Preview < Base
      private

      def limit
        ::Gitlab::CurrentSettings.dashboard_notification_limit
      end

      def feature_enabled?
        return false unless ::Feature.enabled?(:preview_free_user_cap, root_namespace)

        # If we are at the enforcement limit(and it is enabled) we treat this like a switch
        # to turn off preview. This will help in areas that observe both and will ensure
        # only one message is being shown to the user preview or enforcement.
        # The rollout will start with preview having a limit number and being turned on
        # before Standard does.  So this will cover the ones that are 'at' the number
        # but not over for the Standard as they will always get a preview before being
        # enforced with Standard.
        !Standard.new(root_namespace).over_limit?
      end
    end
  end
end

Namespaces::FreeUserCap::Preview.prepend_mod
