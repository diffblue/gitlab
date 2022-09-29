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
        ::Feature.enabled?(:preview_free_user_cap, root_namespace)
      end
    end
  end
end

Namespaces::FreeUserCap::Preview.prepend_mod
