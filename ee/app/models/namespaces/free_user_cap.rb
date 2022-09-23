# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    def self.enforce_preview_or_standard?(namespace)
      # should only be needed temporarily while preview is still in codebase
      # after preview is removed, we should merely call `Standard` in the
      # places that use this. For preview cleanup https://gitlab.com/gitlab-org/gitlab/-/issues/356561
      ::Namespaces::FreeUserCap::Preview.new(namespace).enforce_cap? ||
        ::Namespaces::FreeUserCap::Standard.new(namespace).enforce_cap?
    end

    def self.dashboard_limit
      ::Gitlab::CurrentSettings.dashboard_limit
    end
  end
end

Namespaces::FreeUserCap.prepend_mod
