# frozen_string_literal: true

module EE
  module AccessTokensHelper
    extend ::Gitlab::Utils::Override

    override :expires_at_field_data
    def expires_at_field_data
      return super unless ::License.feature_available?(:personal_access_token_expiration_policy)

      super.merge(max_date: personal_access_token_max_expiry_date&.iso8601)
    end
  end
end
