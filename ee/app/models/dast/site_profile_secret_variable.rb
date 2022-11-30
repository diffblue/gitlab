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

    MIN_VALUE_LENGTH = 8
    MAX_VALUE_LENGTH = 10_000

    validate :decoded_value

    # User input is base64 encoded before being encrypted in order to allow it to be masked by default
    def raw_value=(new_value)
      self.value = Base64.strict_encode64(new_value)
    end

    # Use #raw_value= to ensure value is maskable
    private :value=

    private

    def human_readable_key
      case key
      when PASSWORD then _('Password')
      when REQUEST_HEADERS then _('Request Headers')
      else _('Value')
      end
    end

    def decoded_value
      decoded_value = Base64.strict_decode64(value)

      if decoded_value.length < MIN_VALUE_LENGTH
        errors.add(:base, _('%{human_readable_key} is less than %{min_value_length} characters') % { human_readable_key: human_readable_key, min_value_length: MIN_VALUE_LENGTH })

        return
      end

      return unless decoded_value.length > MAX_VALUE_LENGTH

      errors.add(:base, _('%{human_readable_key} exceeds %{max_value_length} characters') % { human_readable_key: human_readable_key, max_value_length: MAX_VALUE_LENGTH })
    end
  end
end
