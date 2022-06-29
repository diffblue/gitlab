# frozen_string_literal: true

# to be removed upon rollout finishing for https://gitlab.com/gitlab-org/gitlab/-/issues/356561
module Namespaces
  module FreeUserCap
    class Preview < Standard
      def over_limit?
        return false unless enforce_cap?

        users_count_over_free_user_limit?
      end

      private

      def feature_enabled?
        ::Feature.enabled?(:preview_free_user_cap, root_namespace) && !root_namespace.exclude_from_free_user_cap?
      end
    end
  end
end

Namespaces::FreeUserCap::Preview.prepend_mod
