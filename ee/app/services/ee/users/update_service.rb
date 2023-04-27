# frozen_string_literal: true

module EE
  module Users
    module UpdateService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize
      include ::Audit::Changes

      attr_reader :group_id_for_saml

      override :initialize
      def initialize(current_user, params = {})
        super
        @group_id_for_saml = params.delete(:group_id_for_saml)
        @params = params.dup
      end

      private

      def notify_success(user_exists)
        notify_new_user(@user, nil) unless user_exists # rubocop:disable Gitlab/ModuleWithInstanceVariables

        audit_changes(:email, as: 'email address',
                              event_type: 'user_email_address_updated')

        audit_changes(:encrypted_password, as: 'password',
                                           skip_changes: true, event_type: 'user_password_updated')

        audit_changes(:username, as: 'username',
                                 event_type: 'user_username_updated')

        audit_changes(:admin, as: 'admin status',
                              event_type: 'user_admin_status_updated')
      end

      def model
        @user
      end

      override :discard_read_only_attributes
      def discard_read_only_attributes
        super

        discard_name unless name_updatable?
      end

      def discard_name
        params.delete(:name)
      end

      def name_updatable?
        params.delete(:force_name_change) || can?(current_user, :update_name, model)
      end

      override :identity_params
      def identity_params
        if group_id_for_saml.present?
          super.merge(saml_provider_id: saml_provider_id)
        else
          super
        end
      end

      override :provider_attributes
      def provider_attributes
        super.push(:saml_provider_id)
      end

      override :identity_attributes
      def identity_attributes
        super.push(:saml_provider_id)
      end

      override :assign_attributes
      def assign_attributes
        params.reject! { |key, _| SamlProvider::USER_ATTRIBUTES_LOCKED_FOR_MANAGED_ACCOUNTS.include?(key.to_sym) } if model.group_managed_account?
        super
      end

      def saml_provider_id
        strong_memoize(:saml_provider_id) do
          if group_id_for_saml.present?
            group = GroupFinder.new(current_user).execute(id: group_id_for_saml)
            group&.saml_provider&.id
          end
        end
      end
    end
  end
end
