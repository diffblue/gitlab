# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class ReprovisioningService
        attr_reader :identity

        delegate :user, to: :identity

        def initialize(identity)
          @identity = identity
        end

        def execute
          ScimIdentity.transaction do
            identity.update!(active: true)
            unblock_user(user)
          end

          ServiceResponse.success(message: format(_("User %{user} SCIM identity is reactivated"), user: user.name))
        end

        private

        def unblock_user(user)
          user.activate
        end
      end
    end
  end
end
