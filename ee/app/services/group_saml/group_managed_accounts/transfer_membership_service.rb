# frozen_string_literal: true

module GroupSaml
  module GroupManagedAccounts
    class TransferMembershipService
      attr_reader :group, :current_user, :oauth_data, :session, :saml_email

      def initialize(current_user, group, session)
        @current_user = current_user
        @group = group
        @oauth_data = session['oauth_data']
        @saml_email = oauth_data&.info&.email
        @session = session
      end

      def execute
        return unless ::Feature.enabled?(:convert_user_to_group_managed_accounts)

        return false unless current_user.verified_email?(saml_email)

        ApplicationRecord.transaction do
          if destroy_non_gma_identities && leave_non_gma_memberships && transfer_user
            identity_linker = Gitlab::Auth::GroupSaml::IdentityLinker.new(current_user, oauth_data, session, group.saml_provider)
            identity_linker.link

            raise ActiveRecord::Rollback if identity_linker.failed?

            true
          else
            raise ActiveRecord::Rollback
          end
        rescue Gitlab::Auth::Saml::IdentityLinker::UnverifiedRequest
          raise ActiveRecord::Rollback
        end
      end

      private

      def transfer_user
        current_user.managing_group = group
        current_user.email = saml_email
        current_user.encrypted_password = ''
        current_user.save
      end

      def destroy_non_gma_identities
        current_user.identities.all? do |identity|
          identity.destroy
          identity.destroyed?
        end
      end

      def leave_non_gma_memberships
        return true unless ::Feature.enabled?(:remove_non_gma_memberships)

        current_user.members.all? do |member|
          next true if member.source == group
          next true if member.source.owned_by?(current_user)

          Members::DestroyService.new(current_user).execute(member)
          member.destroyed?
        end
      end
    end
  end
end
