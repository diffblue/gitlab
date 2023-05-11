# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      module Group
        class DeprovisioningService < BaseDeprovisioningService
          def execute
            if group.last_owner?(user)
              return error(format(
                             _(
                               "Could not remove %{user} from %{group}. Cannot remove last group owner."),
                              user: user.name,
                              group: group.name
                           )
                          )
            end

            ScimIdentity.transaction do
              identity.update!(active: false)
              remove_group_access
            end

            ServiceResponse.success(message: format(
              _("User %{user} was removed from %{group}."),
              user: user.name,
              group: group.name
            ))
          end

          private

          def remove_group_access
            return unless group_membership

            ::Members::DestroyService.new(user).execute(group_membership, skip_saml_identity: true)
          end

          def group_membership
            group.all_group_members.with_user(user).first
          end
          strong_memoize_attr :group_membership
        end
      end
    end
  end
end
