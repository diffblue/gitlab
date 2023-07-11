# frozen_string_literal: true

module DependencyProxy
  module Packages
    class Setting < ApplicationRecord
      self.primary_key = :project_id

      belongs_to :project, inverse_of: :dependency_proxy_packages_setting

      attr_encrypted :maven_external_registry_username,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_32,
        algorithm: 'aes-256-gcm',
        encode: false,
        encode_iv: false
      attr_encrypted :maven_external_registry_password,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_32,
        algorithm: 'aes-256-gcm',
        encode: false,
        encode_iv: false

      validates :project, presence: true
      validates :maven_external_registry_url, addressable_url: true, if: :maven_external_registry_url?

      validates :maven_external_registry_username, presence: true, if: :maven_external_registry_password?
      validates :maven_external_registry_password, presence: true, if: :maven_external_registry_username?
      validates :maven_external_registry_url,
        :maven_external_registry_username,
        :maven_external_registry_password,
        length: { maximum: 255 }

      validates_with AnyFieldValidator, fields: %w[maven_external_registry_url]

      scope :enabled, -> { where(enabled: true) }
    end
  end
end
