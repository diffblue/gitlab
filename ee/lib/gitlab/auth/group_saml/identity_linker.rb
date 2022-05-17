# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class IdentityLinker < Gitlab::Auth::Saml::IdentityLinker
        attr_reader :saml_provider

        def initialize(current_user, oauth, session, saml_provider)
          super(current_user, oauth, session)

          @saml_provider = saml_provider
        end

        protected

        # rubocop: disable CodeReuse/ActiveRecord
        def identity
          @identity ||= current_user.identities.where(provider: :group_saml,
                                                      saml_provider: saml_provider,
                                                      extern_uid: uid.to_s)
                                    .first_or_initialize
        end
        # rubocop: enable CodeReuse/ActiveRecord

        override :update_group_membership
        def update_group_membership
          auth_hash = AuthHash.new(oauth)
          MembershipUpdater.new(current_user, saml_provider, auth_hash).execute
        end
      end
    end
  end
end
