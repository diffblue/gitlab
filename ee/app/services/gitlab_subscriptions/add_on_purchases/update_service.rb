# frozen_string_literal: true

module GitlabSubscriptions
  module AddOnPurchases
    class UpdateService < ::GitlabSubscriptions::AddOnPurchases::BaseService
      def execute
        return error_response unless add_on_purchase

        update_add_on_purchase ? successful_response : error_response
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def add_on_purchase
        @add_on_purchase ||= GitlabSubscriptions::AddOnPurchase.find_by(
          namespace: namespace,
          add_on: add_on
        )
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def update_add_on_purchase
        attributes = {
          quantity: quantity,
          expires_on: expires_on,
          purchase_xid: purchase_xid
        }.compact

        add_on_purchase.update(attributes)
      end

      def error_response
        if add_on_purchase.nil?
          ServiceResponse.error(
            message: "Add-on purchase for #{add_on_human_reference} does not exist, create a new record instead"
          )
        else
          super
        end
      end
    end
  end
end
