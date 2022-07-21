# frozen_string_literal: true

# to be removed upon rollout finishing for https://gitlab.com/gitlab-org/gitlab/-/issues/356561
module Namespaces
  module FreeUserCap
    class Preview < Standard
      private

      def feature_enabled?
        ::Feature.enabled?(:preview_free_user_cap, root_namespace)
      end
    end
  end
end

Namespaces::FreeUserCap::Preview.prepend_mod
