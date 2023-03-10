# frozen_string_literal: true

module Namespaces
  module ServiceAccounts
    class CreateService < ::Users::ServiceAccounts::CreateService
      extend ::Gitlab::Utils::Override

      private

      override :create_user
      def create_user
        ::Users::AuthorizedCreateService.new(current_user, default_user_params).execute
      end

      def namespace
        namespace_id = params[:namespace_id]
        return unless namespace_id

        Namespace.id_in(namespace_id).first
      end
      strong_memoize_attr :namespace

      override :username_prefix
      def username_prefix
        "service_account_#{namespace.type.downcase}_#{namespace.id}"
      end

      override :default_user_params
      def default_user_params
        super.merge(provisioned_by_group_id: params[:namespace_id])
      end

      override :error_message
      def error_message
        _('ServiceAccount|User does not have permission to create a service account in this namespace.')
      end

      override :can_create_service_account
      def can_create_service_account?
        return false unless namespace

        can?(current_user, :admin_service_accounts, namespace)
      end
    end
  end
end
