# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class DeprovisioningService < BaseDeprovisioningService
        def execute
          ScimIdentity.transaction do
            identity.update!(active: false)
            block_user(user)
          end

          ServiceResponse.success(message: format(_("User %{user} SCIM identity is deactivated"), user: user.name))
        end

        private

        def block_user(user)
          user.system_block
        end
      end
    end
  end
end
