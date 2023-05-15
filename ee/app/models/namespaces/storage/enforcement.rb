# frozen_string_literal: true

module Namespaces
  module Storage
    class Enforcement
      def self.enforce_limit?(namespace)
        root_namespace = namespace.root_ancestor

        ::Gitlab::CurrentSettings.enforce_namespace_storage_limit? &&
          ::Gitlab::CurrentSettings.automatic_purchased_storage_allocation? &&
          ::Feature.enabled?(:namespace_storage_limit, root_namespace) &&
          enforceable_plan?(root_namespace)
      end

      def self.show_pre_enforcement_alert?(namespace)
        root_namespace = namespace.root_ancestor

        if ::Gitlab::CurrentSettings.should_check_namespace_plan? &&
            !root_namespace.paid? &&
            reached_pre_enforcement_notification_limit?(root_namespace)

          return ::Feature.enabled?(:namespace_storage_limit_show_preenforcement_banner, root_namespace)
        end

        false
      end

      def self.reached_pre_enforcement_notification_limit?(root_namespace)
        return false if root_namespace.storage_limit_exclusion.present?

        notification_limit = root_namespace.actual_plan.actual_limits.notification_limit.megabytes
        return false unless notification_limit > 0

        total_storage = ::Namespaces::Storage::RootSize.new(root_namespace).current_size
        purchased_storage = (root_namespace.additional_purchased_storage_size || 0)

        total_storage >= (notification_limit + purchased_storage)
      end

      private_class_method def self.enforceable_plan?(root_namespace)
        return false if root_namespace.opensource_plan?

        if root_namespace.paid?
          ::Feature.enabled?(:enforce_storage_limit_for_paid, root_namespace)
        else
          ::Feature.enabled?(:enforce_storage_limit_for_free, root_namespace)
        end
      end
    end
  end
end
