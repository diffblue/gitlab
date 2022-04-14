# frozen_string_literal: true

module EE
  module Gitlab
    module Auth
      module Saml
        module IdentityLinker
          extend ::Gitlab::Utils::Override

          override :link
          def link
            super

            update_group_membership unless failed?
          end

          def update_group_membership
            auth_hash = ::Gitlab::Auth::Saml::AuthHash.new(oauth)
            ::Gitlab::Auth::Saml::MembershipUpdater.new(current_user, auth_hash).execute
          end
        end
      end
    end
  end
end
