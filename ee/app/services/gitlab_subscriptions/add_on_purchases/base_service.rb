# frozen_string_literal: true

module GitlabSubscriptions
  module AddOnPurchases
    class BaseService
      ImplementationMissingError = Class.new(RuntimeError)

      def initialize(current_user, namespace, add_on, params = {})
        @current_user = current_user
        @namespace = namespace
        @add_on = add_on
        @quantity = params[:quantity]
        @expires_on = params[:expires_on]
        @purchase_xid = params[:purchase_xid]
      end

      def execute
        authorize_current_user!
      end

      private

      attr_reader :current_user, :namespace, :add_on, :quantity, :expires_on, :purchase_xid

      # rubocop: disable Cop/UserAdmin
      def authorize_current_user!
        # Using #admin? is discouraged as it will bypass admin mode authorisation checks,
        # however those checks are not in place in our REST API yet, and this service is only
        # going to be used by the API for admin-only actions
        raise Gitlab::Access::AccessDeniedError unless current_user&.admin?
      end
      # rubocop: enable Cop/UserAdmin

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
    end
  end
end
