# frozen_string_literal: true

module EE
  module Users
    module BuildService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      attr_reader :group_id_for_saml

      GROUP_SAML_PROVIDER = 'group_saml'
      GROUP_SCIM_PROVIDER = 'group_scim'

      override :initialize
      def initialize(current_user, params = {})
        super
        @group_id_for_saml = params.delete(:group_id_for_saml)
      end

      override :execute
      def execute
        super

        build_smartcard_identity if ::Gitlab::Auth::Smartcard.enabled?
        set_pending_approval_state

        user
      end

      private

      override :signup_params
      def signup_params
        super + email_opted_in_params + name_params
      end

      def email_opted_in_params
        [
          :email_opted_in,
          :email_opted_in_ip,
          :email_opted_in_source_id,
          :email_opted_in_at
        ]
      end

      def name_params
        [
          :first_name,
          :last_name
        ]
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      override :assign_common_user_params
      def assign_common_user_params
        super

        @user_params.delete(:provisioned_by_group_id) unless service_account?
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      override :allowed_user_type?
      def allowed_user_type?
        super || service_account?
      end

      def service_account?
        user_params[:user_type]&.to_sym == :service_account
      end

      override :admin_create_params
      def admin_create_params
        super + [:auditor, :provisioned_by_group_id]
      end

      override :identity_attributes
      def identity_attributes
        super.push(:saml_provider_id)
      end

      override :build_identity
      def build_identity
        return super unless params[:provider] == GROUP_SCIM_PROVIDER

        build_scim_identity
        identity_params[:provider] = GROUP_SAML_PROVIDER

        user.provisioned_by_group_id = params[:group_id]

        super
      end

      override :identity_params
      def identity_params
        if group_id_for_saml.present?
          super.merge(saml_provider_id: saml_provider_id)
        else
          super
        end
      end

      def scim_identity_attributes
        [:group_id, :extern_uid]
      end

      def saml_provider_id
        strong_memoize(:saml_provider_id) do
          group = GroupFinder.new(current_user).execute(id: group_id_for_saml)
          group&.saml_provider&.id
        end
      end

      def build_smartcard_identity
        smartcard_identity_attrs = params.slice(:certificate_subject, :certificate_issuer)

        return if smartcard_identity_attrs.empty?

        user.smartcard_identities.build(subject: params[:certificate_subject], issuer: params[:certificate_issuer])
      end

      def build_scim_identity
        scim_identity_params = params.slice(*scim_identity_attributes)

        user.scim_identities.build(scim_identity_params.merge(active: true))
      end

      def set_pending_approval_state
        return unless ::Gitlab::CurrentSettings.should_apply_user_signup_cap?
        return unless user.human?

        user.state = ::User::BLOCKED_PENDING_APPROVAL_STATE
      end
    end
  end
end
