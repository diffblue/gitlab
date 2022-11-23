# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      module Group
        class ReprovisioningService
          attr_reader :identity

          delegate :user, :group, to: :identity

          def initialize(identity)
            @identity = identity
          end

          def execute
            ScimIdentity.transaction do
              identity.update!(active: true)
              add_member unless existing_member?
            end
          end

          private

          def add_member
            group.add_member(user, default_membership_role)
          end

          def default_membership_role
            group.saml_provider.default_membership_role
          end

          def existing_member?
            ::GroupMember.member_of_group?(group, user)
          end
        end
      end
    end
  end
end
