# frozen_string_literal: true

# to be removed upon rollout finishing for https://gitlab.com/gitlab-org/gitlab/-/issues/356561
module Namespaces
  class PreviewFreeUserCap < FreeUserCap
    def over_limit?
      return false unless enforce_cap?

      users_count > FREE_USER_LIMIT
    end

    private

    def feature_enabled?
      ::Feature.enabled?(:preview_free_user_cap, root_namespace, default_enabled: :yaml)
    end
  end
end
