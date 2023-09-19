# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class AuthHash < Gitlab::Auth::Saml::AuthHash
        include Gitlab::Utils::StrongMemoize

        ALLOWED_USER_ATTRIBUTES = %w[can_create_group projects_limit].freeze

        def groups
          Array.wrap(get_raw('groups') || get_raw('Groups'))
        end

        # Access user attributes by hash.
        #
        # auth_hash.user_attributes['can_create_group']
        def user_attributes
          strong_memoize(:user_attributes) do
            ALLOWED_USER_ATTRIBUTES.index_with do |attr|
              Array(get_raw(attr)).first
            end
          end
        end
      end
    end
  end
end
