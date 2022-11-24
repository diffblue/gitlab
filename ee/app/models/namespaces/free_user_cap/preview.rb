# frozen_string_literal: true

# Remove with https://gitlab.com/gitlab-org/gitlab/-/issues/375607
module Namespaces
  module FreeUserCap
    class Preview < Base
      def over_limit?
        return false unless enforce_cap?

        result = users_count > limit

        update_database_fields(result)

        result
      end

      private

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

        # If we are at the enforcement limit(and it is enabled) we treat this like a switch
        # to turn off preview. This will help in areas that observe both and will ensure
        # only one message is being shown to the user preview or enforcement.
        # The rollout will start with preview having a limit number and being turned on
        # before Standard does.  So this will cover the ones that are over the number
        # for Standard as they will always get a preview before being enforced with Standard.
        !Standard.new(root_namespace).over_limit?(update_database: false)
      end
    end
  end
end

Namespaces::FreeUserCap::Preview.prepend_mod
