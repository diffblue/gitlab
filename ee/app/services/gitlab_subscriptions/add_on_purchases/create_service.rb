# frozen_string_literal: true

module GitlabSubscriptions
  module AddOnPurchases
    class CreateService < ::GitlabSubscriptions::AddOnPurchases::BaseService
      def execute
        super

        add_on_purchase.save ? successful_response : error_response
      end

      private

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
            message: "Add-on purchase for namespace #{namespace.id} and add-on #{add_on.name.titleize} " \
                     "already exists, use the update endpoint instead"
          )
        else
          super
        end
      end
    end
  end
end
