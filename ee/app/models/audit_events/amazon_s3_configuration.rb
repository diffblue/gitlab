# frozen_string_literal: true

module AuditEvents
  class AmazonS3Configuration < ApplicationRecord
    include Limitable
    include ExternallyCommonDestinationable

    self.limit_name = 'audit_events_amazon_s3_configurations'
    self.limit_scope = :group
    self.table_name = 'audit_events_amazon_s3_configurations'

    ACCESS_KEY_ID_REGEX = /\A\w+\z/

    belongs_to :group, class_name: '::Group', foreign_key: 'namespace_id', inverse_of: :amazon_s3_configurations

    validates_presence_of :name, :secret_access_key, :group
    validates :name, uniqueness: { scope: :namespace_id }
    validates :access_key_xid, presence: true,
      format: { with: ACCESS_KEY_ID_REGEX, message: 'must be alphanumeric or underscore' },
      length: { in: 16..128 }
    validates :bucket_name, presence: true, length: { maximum: 63 }, uniqueness: { scope: :namespace_id }
    validates :aws_region, presence: true, length: { maximum: 50 }

    attr_encrypted :secret_access_key,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_32,
      algorithm: 'aes-256-gcm',
      encode: false,
      encode_iv: false

    validate :root_level_group?

    private

    def root_level_group?
      errors.add(:group, 'must not be a subgroup') if group&.subgroup?
    end
  end
end
