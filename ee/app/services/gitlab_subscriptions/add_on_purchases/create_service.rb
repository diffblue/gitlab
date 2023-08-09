# frozen_string_literal: true

module GitlabSubscriptions
  module AddOnPurchases
    class CreateService < ::GitlabSubscriptions::AddOnPurchases::BaseService
      def execute
        return root_namespace_error if ::Gitlab::CurrentSettings.should_check_namespace_plan? && !namespace&.root?

        add_on_purchase.save ? successful_response : error_response
      end

      private

      def root_namespace_error
        message = namespace.present? ? "Namespace #{namespace.name} is not a root namespace" : 'No namespace given'

        ServiceResponse.error(message: message)
      end

      def add_on_purchase
        @add_on_purchase ||= GitlabSubscriptions::AddOnPurchase.new(
          namespace: namespace,
          add_on: add_on,
          quantity: quantity,
          expires_on: expires_on,
          purchase_xid: purchase_xid
        )
      end

      def error_response
        if add_on_purchase.errors.of_kind?(:subscription_add_on_id, :taken)
          ServiceResponse.error(
            message: "Add-on purchase for #{add_on_human_reference} already exists, update the existing record"
          )
        else
          super
        end
      end
    end
  end
end
