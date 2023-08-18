# frozen_string_literal: true

module RemoteDevelopment
  class WorkspaceVariable < ApplicationRecord
    belongs_to :workspace, class_name: 'RemoteDevelopment::Workspace', inverse_of: :workspace_variables

    enum variable_type: {
      env_var: 0,
      file: 1
    }, _prefix: :variable_type

    validates :variable_type, presence: true

    validates :key,
      presence: true,
      length: { maximum: 255 }

    attr_encrypted :value,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_32,
      algorithm: 'aes-256-gcm'
  end
end
