# frozen_string_literal: true

module GitlabSubscriptions
  module AddOnPurchases
    class BaseService
      ImplementationMissingError = Class.new(RuntimeError)

      def initialize(namespace, add_on, params = {})
        @namespace = namespace
        @add_on = add_on
        @quantity = params[:quantity]
        @expires_on = params[:expires_on]
        @purchase_xid = params[:purchase_xid]
      end

      def execute
        raise ImplementationMissingError, 'Override in derived class'
      end

      private

      attr_reader :namespace, :add_on, :quantity, :expires_on, :purchase_xid

      # Override in derived class
      def add_on_purchase
        raise ImplementationMissingError, 'Override in derived class'
      end

      def successful_response
        ServiceResponse.success(payload: { add_on_purchase: add_on_purchase })
      end

      def error_response
        ServiceResponse.error(
          message: 'Add-on purchase could not be saved',
          payload: { add_on_purchase: add_on_purchase }
        )
      end

      def add_on_human_reference
        str = ''
        str += "namespace #{namespace.name} and " if namespace
        str += "add-on #{add_on.name.titleize}"
        str
      end
    end
  end
end
