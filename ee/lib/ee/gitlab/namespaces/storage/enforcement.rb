# frozen_string_literal: true

module EE
  module Gitlab
    module Namespaces
      module Storage
        class Enforcement
          ENFORCEMENT_DATE = 100.years.from_now.to_date
          EFFECTIVE_DATE = 99.years.from_now.to_date
          FREE_NAMESPACE_STORAGE_CAP = 5.gigabytes

          def self.enforce_limit?(namespace)
            root_namespace = namespace.root_ancestor

            ::Gitlab::CurrentSettings.enforce_namespace_storage_limit? &&
              ::Gitlab::CurrentSettings.automatic_purchased_storage_allocation? &&
              ::Feature.enabled?(:namespace_storage_limit, root_namespace) &&
              enforceable_plan?(root_namespace) &&
              enforceable_dates?(root_namespace)
          end

          def self.show_pre_enforcement_banner?(namespace)
            root_namespace = namespace.root_ancestor

            return false unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
            return false unless ::Gitlab::CurrentSettings.enforce_namespace_storage_limit?
            return false if root_namespace.paid?
            return false unless has_breached_free_storage_cap?(root_namespace)
            return false unless root_namespace.storage_enforcement_date.present?
            return false unless root_namespace.storage_enforcement_date >= Date.today

            ::Feature.enabled?(:namespace_storage_limit_show_preenforcement_banner, root_namespace)
          end

          private_class_method def self.has_breached_free_storage_cap?(root_namespace)
            (root_namespace.root_storage_statistics&.storage_size || 0) >= FREE_NAMESPACE_STORAGE_CAP
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
  end
end
