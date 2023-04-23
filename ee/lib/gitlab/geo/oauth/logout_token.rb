# frozen_string_literal: true

module Gitlab
  module Geo
    module Oauth
      class LogoutToken
        include ActiveModel::Validations
        include Gitlab::Utils::StrongMemoize

        validates :current_user, :token, presence: { message: 'could not be found' }
        validate :owner, if: :token
        validate :status, if: :token

        def initialize(current_user, raw_state)
          @current_user = current_user
          @raw_state = raw_state
        end

        def return_to
          return unless valid?
          return unless node

          Gitlab::Utils.append_path(node.url, state.return_to)
        end

        private

        attr_reader :current_user, :raw_state

        def state
          strong_memoize(:state) do
            Gitlab::Geo::Oauth::LogoutState.from_state(raw_state)
          end
        end

        def token
          strong_memoize(:token) do
            decoded_token = state.decode

            if decoded_token&.is_utf8?
              Doorkeeper::AccessToken.by_token(decoded_token)
            end
          end
        end

        def node
          strong_memoize(:node) do
            GeoNode.find_by_oauth_application_id(token.application_id)
          end
        end

        def status
          result = AccessTokenValidationService.new(token).validate

          unless result == AccessTokenValidationService::VALID
            errors.add(:base, "Token has #{result}")
          end
        end

        def owner
          resource_owner = User.find(token.resource_owner_id)

          unless resource_owner && resource_owner == current_user
            errors.add(:base, 'User could not be found')
          end
        end
      end
    end
  end
end
