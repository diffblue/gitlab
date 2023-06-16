# frozen_string_literal: true

module Namespaces
  module Storage
    module Enforcement
      extend self

      def enforce_limit?(namespace)
        root_namespace = namespace.root_ancestor

        ::Gitlab::CurrentSettings.enforce_namespace_storage_limit? &&
          ::Gitlab::CurrentSettings.automatic_purchased_storage_allocation? &&
          ::Feature.enabled?(:namespace_storage_limit, root_namespace) &&
          enforceable_namespace?(root_namespace)
      end

      def show_pre_enforcement_alert?(namespace)
        root_namespace = namespace.root_ancestor

        ::Gitlab::CurrentSettings.should_check_namespace_plan? &&
          !root_namespace.paid? &&
          over_pre_enforcement_notification_limit?(root_namespace) &&
          ::Feature.enabled?(:namespace_storage_limit_show_preenforcement_banner, root_namespace)
      end

      def over_pre_enforcement_notification_limit?(root_namespace)
        return false if root_namespace.storage_limit_exclusion.present?

        # The storage usage limit used for comparing whether to display the phased notification or not.
        # It should not be confused with the dashboard limit called storage_size_limit.
        # This particular setting is saved in megabytes, so we should utilize the '.megabytes' method.
        notification_limit = root_namespace.actual_plan.actual_limits.notification_limit.megabytes
        return false unless notification_limit > 0

        total_storage = ::Namespaces::Storage::RootSize.new(root_namespace).current_size
        purchased_storage = (root_namespace.additional_purchased_storage_size || 0).megabytes

        total_storage > (notification_limit + purchased_storage)
      end

      def enforceable_storage_limit(root_namespace)
        # no limit for excluded namespaces
        return 0 if root_namespace.storage_limit_exclusion.present?

        plan_limit = root_namespace.actual_limits

        # use dashboard limit (storage_size_limit) if:
        # - enabled (determined by timestamp)
        # - namespace was created after the timestamp
        return plan_limit.storage_size_limit if dashboard_limit_applicable?(root_namespace, plan_limit)

        # otherwise, we use enforcement limit as it's either not set (default db value is 0)
        # or it has value to enforce
        plan_limit.enforcement_limit
      end

      private

      def enforceable_namespace?(root_namespace)
        return false if root_namespace.opensource_plan?
        return false if root_namespace.paid?

        enforceable_storage_limit(root_namespace) > 0
      end

      def dashboard_limit_applicable?(root_namespace, plan_limit)
        plan_limit.dashboard_storage_limit_enabled? &&
          root_namespace.created_at > plan_limit.dashboard_limit_enabled_at
      end
    end
  end
end
