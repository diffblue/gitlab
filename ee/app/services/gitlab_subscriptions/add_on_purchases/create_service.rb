# frozen_string_literal: true

module GitlabSubscriptions
  module AddOnPurchases
    class CreateService < ::GitlabSubscriptions::AddOnPurchases::BaseService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        super

        return root_namespace_error unless namespace.root?

        add_on_purchase.save ? successful_response : error_response
      end

      private

      def root_namespace_error
        ServiceResponse.error(message: "Namespace #{namespace.id} is not a root namespace")
      end

      override :add_on_purchase
      def add_on_purchase
        @add_on_purchase ||= GitlabSubscriptions::AddOnPurchase.new(
          namespace: namespace,
          add_on: add_on,
          quantity: quantity,
          expires_on: expires_on,
          purchase_xid: purchase_xid
        )
      end

      override :error_response
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
