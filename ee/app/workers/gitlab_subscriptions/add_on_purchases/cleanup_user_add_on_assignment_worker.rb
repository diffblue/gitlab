# frozen_string_literal: true

module GitlabSubscriptions
  module AddOnPurchases
    class CleanupUserAddOnAssignmentWorker
      include ::ApplicationWorker

      feature_category :seat_cost_management

      data_consistency :sticky
      urgency :low

      deduplicate :until_executed, if_deduplicated: :reschedule_once
      idempotent!

      def perform(root_namespace_id, user_id)
        @root_namespace_id = root_namespace_id
        @user_id           = user_id

        return unless root_namespace && user && add_on_purchase && assignment

        return if eligible_for_seat?

        assignment.destroy!

        log_event
      end

      private

      attr_reader :user_id, :root_namespace_id

      def user
        @user ||= User.find_by_id(user_id)
      end

      def root_namespace
        @root_namespace ||= Group.find_by_id(root_namespace_id)
      end

      def add_on_purchase
        @add_on_purchase ||= root_namespace.subscription_add_on_purchases.for_code_suggestions.first
      end

      def assignment
        @assignment ||= add_on_purchase.assigned_users.by_user(user).first
      end

      def eligible_for_seat?
        root_namespace.eligible_for_code_suggestions_seat?(user)
      end

      def log_event
        Gitlab::AppLogger.info(
          message: 'AddOnPurchase user assignment destroyed',
          user: user.username.to_s,
          add_on: add_on_purchase.add_on.name,
          namespace: root_namespace.path
        )
      end
    end
  end
end
