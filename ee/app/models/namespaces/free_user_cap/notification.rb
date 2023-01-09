# frozen_string_literal: true

# Remove with https://gitlab.com/gitlab-org/gitlab/-/issues/375607
module Namespaces
  module FreeUserCap
    class Notification < Base
      def over_limit?
        return false unless enforce_cap?

        result = users_count > limit

        log_user_counts
        update_database_fields(result)

        result
      end

      private

      def log_user_counts
        data = {
          message: 'Namespace qualifies for counting users',
          class: self.class.name,
          namespace_id: root_namespace.id
        }.merge(full_user_counts)

        Gitlab::AppLogger.info(data)
      end

      def update_database_fields(result)
        Rails.cache.fetch([self.class.name, root_namespace.id], expires_in: 1.day) do
          value = result ? Time.current : nil
          namespace_details = root_namespace.namespace_details
          # check for presence sometimes in test the namespace_details record isn't created
          next unless namespace_details.present?
          next if value && namespace_details.dashboard_notification_at.present?

          namespace_details.update(dashboard_notification_at: value)
        end
      end

      def limit
        ::Gitlab::CurrentSettings.dashboard_notification_limit
      end

      def feature_enabled?
        return false unless ::Feature.enabled?(:preview_free_user_cap, root_namespace)

        # before Enforcement does.  So this will cover the ones that are over the number
        # for Enforcement as they will always get a notification before being enforced with Enforcement.
        !Enforcement.new(root_namespace).over_limit?(update_database: false)
      end
    end
  end
end

Namespaces::FreeUserCap::Notification.prepend_mod
