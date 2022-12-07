# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    # Remove/Merge back into Standard with https://gitlab.com/gitlab-org/gitlab/-/issues/375607
    class Base
      include Gitlab::Utils::StrongMemoize

      def initialize(root_namespace)
        @root_namespace = root_namespace.root_ancestor # just in case the true root isn't passed
      end

      def enforce_cap?
        return false unless enforceable_subscription?

        feature_enabled?
      end
      strong_memoize_attr :enforce_cap?, :enforce_cap

      def users_count
        ::Namespaces::FreeUserCap::UsersFinder.count(root_namespace)
      end
      strong_memoize_attr :users_count

      private

      attr_reader :root_namespace

      def enforceable_subscription?
        return false unless ::Gitlab::CurrentSettings.dashboard_limit_enabled?
        return false unless root_namespace.group_namespace?
        return false if root_namespace.public?

        root_namespace.has_free_or_no_subscription?
      end

      def feature_enabled?
        raise NotImplementedError
      end
    end
  end
end

Namespaces::FreeUserCap::Base.prepend_mod
