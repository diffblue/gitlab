# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class IdentityLinker < Gitlab::Auth::Saml::IdentityLinker
        include ::Gitlab::Utils::StrongMemoize
        attr_reader :saml_provider, :auth_hash

        def initialize(current_user, oauth, session, saml_provider)
          super(current_user, oauth, session)

          @auth_hash = AuthHash.new(oauth)
          @saml_provider = saml_provider
        end

        override :link
        def link
          super

          update_extern_uid if extern_uid_update_required?
        end

        override :failed?
        def failed?
          super || update_extern_uid_failed?
        end

        override :error_message
        def error_message
          return super unless update_extern_uid_failed?

          s_('GroupSAML|SAML Name ID and email address do not match your user account. Contact an administrator.')
        end

        private

        # rubocop: disable CodeReuse/ActiveRecord
        override :identity
        def identity
          current_user.identities
                      .where(provider: :group_saml, saml_provider: saml_provider)
                      .first_or_initialize(extern_uid: uid.to_s)
        end
        strong_memoize_attr :identity
        # rubocop: enable CodeReuse/ActiveRecord

        override :update_group_membership
        def update_group_membership
          auth_hash = AuthHash.new(oauth)
          MembershipUpdater.new(current_user, saml_provider, auth_hash).execute
        end

        def update_extern_uid
          existing_extern_uid = identity.extern_uid

          success = if update_extern_uid_allowed?
                      identity.extern_uid = uid.to_s
                      save
                    else
                      false
                    end

          audit(success, existing_extern_uid, uid.to_s)
        end

        # When the current extern_uid doesn't match the
        # uid (Name ID) from SAML, we need to update.
        def extern_uid_update_required?
          identity.extern_uid != uid.to_s
        end

        # Updating the extern_uid is only allowed if the email
        # address sent from the IdP matches a verified email
        # address of the current user. This prevents accidentally
        # linking an unintended IdP account.
        def update_extern_uid_allowed?
          current_user.verified_email?(auth_hash.email)
        end
        strong_memoize_attr :update_extern_uid_allowed?

        def update_extern_uid_failed?
          extern_uid_update_required? && !update_extern_uid_allowed?
        end

        def audit(success, old_uid, new_uid)
          action = success ? "Updated" : "Failed to update"

          audit_context = {
            name: 'update_mismatched_group_saml_extern_uid',
            author: current_user,
            scope: current_user,
            target: current_user,
            message: "#{action} extern_uid from #{old_uid} to #{new_uid}"
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
