# frozen_string_literal: true

module GitlabSubscriptions
  module AddOnPurchases
    class RefreshUserAssignmentsWorker
      include ::ApplicationWorker

      feature_category :seat_cost_management

      data_consistency :sticky
      urgency :low

      deduplicate :until_executed, if_deduplicated: :reschedule_once
      idempotent!

      def perform(root_namespace_id)
        @root_namespace_id = root_namespace_id

        return unless root_namespace && add_on_purchase

        add_on_purchase.assigned_users.find_in_batches do |batch|
          assignments_to_delete_ids = []

          batch.each do |assignment|
            next if eligible_for_seat?(assignment.user)

            assignments_to_delete_ids << assignment.id
          end

          GitlabSubscriptions::UserAddOnAssignment.by_ids(assignments_to_delete_ids).delete_all
        end
      end

      private

      attr_reader :root_namespace_id

      def root_namespace
        @root_namespace ||= Group.find_by_id(root_namespace_id)
      end

      def add_on_purchase
        @add_on_purchase ||= root_namespace.subscription_add_on_purchases.for_code_suggestions.first
      end

      def eligible_for_seat?(user)
        root_namespace.eligible_for_code_suggestions_seat?(user)
      end
    end
  end
end
