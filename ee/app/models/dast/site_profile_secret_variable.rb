# frozen_string_literal: true

module Dast
  class SiteProfileSecretVariable < ApplicationRecord
    REQUEST_HEADERS = 'DAST_REQUEST_HEADERS_BASE64'
    API_REQUEST_HEADERS = 'DAST_API_REQUEST_HEADERS_BASE64'
    PASSWORD = 'DAST_PASSWORD_BASE64'
    API_PASSWORD = 'DAST_API_HTTP_PASSWORD_BASE64'

    API_SCAN_VARIABLES_MAP = { REQUEST_HEADERS => API_REQUEST_HEADERS, PASSWORD => API_PASSWORD }.freeze

    include Ci::HasVariable
    include Ci::Maskable

    self.table_name = 'dast_site_profile_secret_variables'

    belongs_to :dast_site_profile
    delegate :project, to: :dast_site_profile, allow_nil: false

    attribute :masked, default: true

    attr_encrypted :value,
      mode: :per_attribute_iv,
      algorithm: 'aes-256-gcm',
      key: Settings.attr_encrypted_db_key_base_32,
      encode: false # No need to encode for binary column https://github.com/attr-encrypted/attr_encrypted#the-encode-encode_iv-encode_salt-and-default_encoding-options

    validates :dast_site_profile_id, presence: true

    # Secret variables must be masked to prevent them being readable in CI jobs
    validates :masked, inclusion: { in: [true] }
    validates :variable_type, inclusion: { in: ['env_var'] }

    validates :key, uniqueness: { scope: :dast_site_profile_id, message: N_('(%{value}) has already been taken') }

    # Since user input is base64 encoded before being encrypted, we must validate against the encoded length
    MAX_VALUE_LENGTH = 10_000
    MAX_ENCODED_VALUE_LENGTH = ((4 * MAX_VALUE_LENGTH / 3) + 3) & ~3

    validates :value, length: {
      maximum: MAX_ENCODED_VALUE_LENGTH, # encoded user input length
      too_long: -> (object, data) { _('exceeds the %{max_value_length} character limit') % { max_value_length: MAX_VALUE_LENGTH } } # user input length
    }

    # User input is base64 encoded before being encrypted in order to allow it to be masked by default
    def raw_value=(new_value)
      self.value = Base64.strict_encode64(new_value)
    end

    # Use #raw_value= to ensure value is maskable
    private :value=
  end
end
