# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class Enforcement
      def initialize(root_namespace)
        @root_namespace = root_namespace.root_ancestor # just in case the true root isn't passed
      end

      def enforce_cap?(cache: true)
        return preloaded_enforce_cap[root_namespace.id] if cache

        return false unless enforceable_subscription?

        feature_enabled?
      end

      def over_limit?(update_database: true)
        return false unless enforce_cap?

        result = users_count > limit

        update_database_fields(result) if update_database

        result
      end

      def reached_limit?
        return false unless enforce_cap?

        users_count >= limit
      end

      def at_limit?
        return false unless enforce_cap?

        users_count == limit
      end

      def seat_available?(user)
        return true unless enforce_cap?
        return true if member_with_user_already_exists?(user)

        users_count(cache: false) < limit
      end

      def close_to_dashboard_limit?
        return false unless enforce_cap?
        return false if reached_limit?

        users_count >= (limit - CLOSE_TO_LIMIT_COUNT_DIFFERENCE)
      end

      def remaining_seats
        [limit - users_count, 0].max
      end

      def git_check_over_limit!(error_class)
        return unless over_limit?

        raise error_class, git_read_only_message
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

      CLOSE_TO_LIMIT_COUNT_DIFFERENCE = 2

      def update_database_fields(result)
        Rails.cache.fetch([self.class.name, root_namespace.id], expires_in: 1.day) do
          value = result ? Time.current : nil
          namespace_details = root_namespace.namespace_details
          # check for presence sometimes in test the namespace_details record isn't created
          next unless namespace_details.present?
          next if value && namespace_details.dashboard_enforcement_at.present?

          namespace_details.update(dashboard_enforcement_at: value)
        end
      end

      def full_user_counts(cache: true)
        return preloaded_users_count[root_namespace.id] if cache

        ::Namespaces::FreeUserCap::UsersFinder.count(root_namespace, database_limit)
      end

      def database_limit
        ::Gitlab::CurrentSettings.dashboard_limit + 1
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

      def limit
        Namespaces::FreeUserCap.dashboard_limit
      end

      def member_with_user_already_exists?(user)
        # it is possible for members to not have a user filled out in cases like being an invite
        user && ::Member.in_hierarchy(root_namespace).with_user(user).exists?
      end

      def feature_enabled?
        ::Feature.enabled?(:free_user_cap, root_namespace)
      end

      def git_read_only_message
        _('Your top-level group is over the user limit and has been placed in a read-only state.')
      end
    end
  end
end

Namespaces::FreeUserCap::Enforcement.prepend_mod
