# frozen_string_literal: true

module AuditEvents
  class GoogleCloudLoggingConfiguration < ApplicationRecord
    include Limitable

    self.limit_name = 'google_cloud_logging_configurations'
    self.limit_scope = :group
    self.table_name = 'audit_events_google_cloud_logging_configurations'

    GOOGLE_PROJECT_ID_NAME_REGEX = %r{\A[a-z][a-z0-9-]*[a-z0-9]\z}
    LOG_ID_NAME_REGEX = %r{\A[\w/.-]+\z}

    belongs_to :group, class_name: '::Group', foreign_key: 'namespace_id',
      inverse_of: :google_cloud_logging_configurations

    validates :google_project_id_name, presence: true,
      format: { with: GOOGLE_PROJECT_ID_NAME_REGEX,
                message: 'must only contain lowercase letters, digits, or hyphens, ' \
                         'and must start and end with a letter or digit' },
      length: { in: 6..30 }

    validates :log_id_name, presence: true,
      format: { with: LOG_ID_NAME_REGEX,
                message: 'must only contain letters, digits, forward-slash, underscore, hyphen or period' },
      length: { maximum: 511 }

    validates :client_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 254 }
    validates :private_key, presence: true

    attr_encrypted :private_key,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_32,
      algorithm: 'aes-256-gcm',
      encode: false,
      encode_iv: false

    validate :root_level_group?

    private

    def root_level_group?
      errors.add(:group, 'must not be a subgroup') if group.subgroup?
    end
  end
end
