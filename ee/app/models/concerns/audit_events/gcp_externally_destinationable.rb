# frozen_string_literal: true

module AuditEvents
  module GcpExternallyDestinationable
    extend ActiveSupport::Concern

    GOOGLE_PROJECT_ID_NAME_REGEX = %r{\A[a-z][a-z0-9-]*[a-z0-9]\z}
    LOG_ID_NAME_REGEX = %r{\A[\w/.-]+\z}

    DEFAULT_LOG_ID_NAME = "audit_events"

    included do
      attribute :log_id_name, :string, default: DEFAULT_LOG_ID_NAME

      validates :log_id_name, presence: true,
        format: { with: LOG_ID_NAME_REGEX,
                  message: ->(_object, _data) {
                    _('must only contain letters, digits, forward-slash, underscore, hyphen or period')
                  } },
        length: { maximum: 511 }

      validates :client_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 254 }
      validates :private_key, presence: true

      validates :google_project_id_name, presence: true,
        format: {
          with: GOOGLE_PROJECT_ID_NAME_REGEX,
          message: 'must only contain lowercase letters, digits, or hyphens, ' \
                   'and must start and end with a letter or digit'
        },
        length: { in: 6..30 }

      attr_encrypted :private_key,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_32,
        algorithm: 'aes-256-gcm',
        encode: false,
        encode_iv: false

      def allowed_to_stream?(*)
        true
      end

      def full_log_path
        "projects/#{google_project_id_name}/logs/#{log_id_name}"
      end
    end
  end
end
