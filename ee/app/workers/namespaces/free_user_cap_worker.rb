# frozen_string_literal: true

module Namespaces
  class FreeUserCapWorker
    include ApplicationWorker
    include CronjobQueue

    MAX_NAMESPACES_TO_TRIM = 10_000

    feature_category :free_user_caps_conversion
    data_consistency :always
    idempotent!
    worker_resource_boundary :cpu

    # :nocov:
    def perform
      return unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
      return unless ::Namespaces::FreeUserCap.trimming_enabled?

      count = 0
      Namespace.in_default_plan.top_most.find_each do |namespace|
        break if count >= MAX_NAMESPACES_TO_TRIM

        next unless ::Namespaces::FreeUserCap.new(namespace).enforce_cap?

        with_context(namespace: namespace) do
          if namespace.memberships_to_be_deactivated.any?
            Namespaces::DeactivateMembersOverLimitService.new(namespace).execute
            count += 1
          end

          remediate_group_sharing(namespace)
        end
      rescue StandardError => ex
        logger.error("Cannot remediate namespace with ID=#{namespace.id} due to: #{ex} in #{count} run")
      end
    end
    # :nocov:

    private

    def remediate_group_sharing(namespace)
      return unless ::Namespaces::FreeUserCap.group_sharing_remediation_enabled?

      Namespaces::UpdatePreventSharingOutsideHierarchyService.new(namespace).execute
      Namespaces::RemoveProjectGroupLinksOutsideHierarchyService.new(namespace).execute
      Namespaces::RemoveGroupGroupLinksOutsideHierarchyService.new(namespace).execute
    end
  end
end
