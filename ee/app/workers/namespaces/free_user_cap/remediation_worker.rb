# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class RemediationWorker
      include ApplicationWorker
      include CronjobQueue

      MAX_NAMESPACES_TO_TRIM = 10_000

      feature_category :experimentation_conversion
      data_consistency :always
      idempotent!
      worker_resource_boundary :cpu

      # :nocov:
      def perform
        return unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
        return unless ::Namespaces::FreeUserCap.trimming_enabled?

        count = 0
        Group.in_default_plan.top_most.non_public_only.find_each do |namespace|
          break if count >= MAX_NAMESPACES_TO_TRIM

          next unless ::Namespaces::FreeUserCap::Standard.new(namespace).enforce_cap?

          with_context(namespace: namespace) do
            if namespace.memberships_to_be_deactivated.any?
              Namespaces::FreeUserCap::DeactivateMembersOverLimitService.new(namespace).execute
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

        Namespaces::FreeUserCap::UpdatePreventSharingOutsideHierarchyService.new(namespace).execute
        Namespaces::FreeUserCap::RemoveProjectGroupLinksOutsideHierarchyService.new(namespace).execute
        Namespaces::FreeUserCap::RemoveGroupGroupLinksOutsideHierarchyService.new(namespace).execute
      end
    end
  end
end
