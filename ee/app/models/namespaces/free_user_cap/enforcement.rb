# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class Enforcement < Base
      def over_limit?(cache: false, update_database: true)
        return preloaded_over_limit[root_namespace.id] if cache
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
        return false unless new_namespace_enforcement?

        users_count == limit
      end

      def seat_available?(user)
        return true unless enforce_cap?
        return true if member_with_user_already_exists?(user)

        users_count(cache: false) < limit
      end

      def close_to_dashboard_limit?
        return false unless enforce_cap?
        return false unless new_namespace_enforcement?
        return false if reached_limit?

        users_count >= (limit - CLOSE_TO_LIMIT_COUNT_DIFFERENCE)
      end

      def remaining_seats
        [limit - users_count, 0].max
      end

      def git_check_over_limit!(error_class)
        return unless over_limit?

        over_storage_limit = if block_given?
                               yield
                             else
                               root_namespace.over_storage_limit?
                             end

        raise error_class, git_read_only_message(over_storage_limit)
      end

      private

      CLOSE_TO_LIMIT_COUNT_DIFFERENCE = 2

      def preloaded_over_limit
        resource_key = 'free_user_cap_for_over_limit'

        ::Gitlab::SafeRequestLoader.execute(resource_key: resource_key, resource_ids: [root_namespace.id]) do
          { root_namespace.id => over_limit? }
        end
      end

      def update_database_fields(result)
        Rails.cache.fetch([self.class.name, root_namespace.id], expires_in: 1.day) do
          value = result ? Time.current : nil
          namespace_details = root_namespace.namespace_details
          # check for presence sometimes in test the namespace_details record isn't created
          next unless namespace_details.present?
          next if value && namespace_details.dashboard_enforcement_at.present?

          namespace_details.update(dashboard_enforcement_at: value)

          # to ensure proper data analysis, we need to remove notification when we are in enforcement
          if namespace_details.dashboard_notification_at.present? && value
            namespace_details.update(dashboard_notification_at: nil)
          end
        end
      end

      def limit
        if new_namespace_enforcement?
          Namespaces::FreeUserCap.dashboard_limit
        else
          ::Gitlab::CurrentSettings.dashboard_enforcement_limit
        end
      end

      def member_with_user_already_exists?(user)
        # it is possible for members to not have a user filled out in cases like being an invite
        user && ::Member.in_hierarchy(root_namespace).with_user(user).exists?
      end

      def new_namespace_enforcement?
        return false unless ::Feature.enabled?(:free_user_cap_new_namespaces, root_namespace)
        return false unless ::Gitlab::CurrentSettings.dashboard_limit_new_namespace_creation_enforcement_date.present?

        root_namespace.created_at >= ::Gitlab::CurrentSettings.dashboard_limit_new_namespace_creation_enforcement_date
      end

      def feature_enabled?
        ::Feature.enabled?(:free_user_cap, root_namespace) || new_namespace_enforcement?
      end

      def git_read_only_message(over_storage_limit)
        if over_storage_limit
          _('Your namespace is over the user and storage limits and has been placed in a read-only state.')
        else
          _('Your namespace is over the user limit and has been placed in a read-only state.')
        end
      end
    end
  end
end

Namespaces::FreeUserCap::Enforcement.prepend_mod
