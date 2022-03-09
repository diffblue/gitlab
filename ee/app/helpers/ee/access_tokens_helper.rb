# frozen_string_literal: true

module EE
  module AccessTokensHelper
    extend ::Gitlab::Utils::Override

    override :expires_at_field_data
    def expires_at_field_data
      {
        max_date: personal_access_token_max_expiry_date&.iso8601
      }
    end
  end
end
