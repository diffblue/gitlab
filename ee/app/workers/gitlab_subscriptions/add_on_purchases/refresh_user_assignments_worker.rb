# frozen_string_literal: true

module GitlabSubscriptions
  module AddOnPurchases
    class RefreshUserAssignmentsWorker
      include ::ApplicationWorker
      include Gitlab::ExclusiveLeaseHelpers

      BATCH_SIZE = 50

      feature_category :seat_cost_management

      data_consistency :sticky
      urgency :low

      deduplicate :until_executed, if_deduplicated: :reschedule_once
      idempotent!

      def perform(root_namespace_id)
        @root_namespace_id = root_namespace_id

        return unless root_namespace && add_on_purchase

        deleted_assignments_count = 0
        add_on_purchase.assigned_users.each_batch(of: BATCH_SIZE) do |batch|
          ineligible_user_ids = batch.pluck_user_ids.to_set - eligible_user_ids

          deleted_assignments_count += batch.for_user_ids(ineligible_user_ids).delete_all
        end

        log_event(deleted_assignments_count) if deleted_assignments_count > 0
      end

      private

      attr_reader :root_namespace_id

      def root_namespace
        @root_namespace ||= Group.find_by_id(root_namespace_id)
      end

      def add_on_purchase
        @add_on_purchase ||= root_namespace.subscription_add_on_purchases.for_code_suggestions.first
      end

      def eligible_user_ids
        @eligible_user_ids ||= root_namespace.code_suggestions_eligible_user_ids
      end

      def log_event(deleted_count)
        Gitlab::AppLogger.info(
          message: 'AddOnPurchase user assignments refreshed in bulk',
          deleted_assignments_count: deleted_count,
          add_on: add_on_purchase.add_on.name,
          namespace: root_namespace.path
        )
      end
    end
  end
end
