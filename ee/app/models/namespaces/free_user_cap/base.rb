# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    # Remove/Merge back into Standard with https://gitlab.com/gitlab-org/gitlab/-/issues/375607
    class Base
      include Gitlab::Utils::StrongMemoize

      def initialize(root_namespace)
        @root_namespace = root_namespace.root_ancestor # just in case the true root isn't passed
      end

      def enforce_cap?(cache: true)
        return preloaded_enforce_cap[root_namespace.id] if cache

        return false unless enforceable_subscription?

        feature_enabled?
      end

      def users_count(cache: true)
        full_user_counts(cache: cache)[:user_ids]
      end

      def qualified_namespace?
        return false unless ::Gitlab::CurrentSettings.dashboard_limit_enabled?
        return false unless root_namespace.group_namespace?

        !root_namespace.public?
      end

      private

      attr_reader :root_namespace

      def full_user_counts(cache: true)
        return preloaded_users_count[root_namespace.id] if cache

        ::Namespaces::FreeUserCap::UsersFinder.count(root_namespace, database_limit)
      end

      def database_limit
        max_limit + 1
      end

      def enforceable_subscription?
        return false unless qualified_namespace?
        return false if above_size_limit?

        root_namespace.has_free_or_no_subscription?
      end

      def preloaded_enforce_cap
        resource_key = "free_user_cap_enforce_cap:#{self.class.name}"

        ::Gitlab::SafeRequestLoader.execute(resource_key: resource_key, resource_ids: [root_namespace.id]) do
          { root_namespace.id => enforce_cap?(cache: false) }
        end
      end

      def preloaded_users_count
        resource_key = 'free_user_cap_full_user_counts'

        ::Gitlab::SafeRequestLoader.execute(resource_key: resource_key, resource_ids: [root_namespace.id]) do
          { root_namespace.id => full_user_counts(cache: false) }
        end
      end

      def above_size_limit?
        ::Namespaces::FreeUserCap::RootSize.new(root_namespace).above_size_limit?
      end

      def max_limit
        [
          ::Gitlab::CurrentSettings.dashboard_limit,
          ::Gitlab::CurrentSettings.dashboard_notification_limit,
          ::Gitlab::CurrentSettings.dashboard_enforcement_limit
        ].max
      end

      def feature_enabled?
        raise NotImplementedError
      end
    end
  end
end

Namespaces::FreeUserCap::Base.prepend_mod
