# frozen_string_literal: true

module Namespaces
  module Storage
    class EnforcementCheckService
      ENFORCEMENT_DATE = 100.years.from_now.to_date
      EFFECTIVE_DATE = 99.years.from_now.to_date

      def self.enforce_limit?(namespace)
        root_namespace = namespace.root_ancestor

        ::Gitlab::CurrentSettings.enforce_namespace_storage_limit? &&
          ::Gitlab::CurrentSettings.automatic_purchased_storage_allocation? &&
          ::Feature.enabled?(:namespace_storage_limit, root_namespace) &&
          enforceable_plan?(root_namespace) &&
          enforceable_dates?(root_namespace)
      end

      private_class_method def self.enforceable_plan?(root_namespace)
        return false if root_namespace.opensource_plan?

        if root_namespace.paid?
          ::Feature.enabled?(:enforce_storage_limit_for_paid, root_namespace)
        else
          ::Feature.enabled?(:enforce_storage_limit_for_free, root_namespace)
        end
      end

      private_class_method def self.enforceable_dates?(root_namespace)
        ::Feature.enabled?(:namespace_storage_limit_bypass_date_check, root_namespace) ||
          (Date.current >= ENFORCEMENT_DATE && root_namespace.gitlab_subscription.start_date >= EFFECTIVE_DATE)
      end
    end
  end
end
