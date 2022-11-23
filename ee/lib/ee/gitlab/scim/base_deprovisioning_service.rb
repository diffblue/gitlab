# frozen_string_literal: true
module EE
  module Gitlab
    module Scim
      class BaseDeprovisioningService
        include ::Gitlab::Utils::StrongMemoize

        attr_reader :identity

        delegate :user, :group, to: :identity

        def initialize(identity)
          @identity = identity
        end

        private

        def error(message)
          ServiceResponse.error(message: message)
        end
      end
    end
  end
end
