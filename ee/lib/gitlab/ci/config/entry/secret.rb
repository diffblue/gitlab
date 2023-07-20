# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a secret definition.
        #
        class Secret < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[vault file azure_key_vault token].freeze

          attributes ALLOWED_KEYS

          entry :vault, Entry::Vault::Secret, description: 'Vault secrets engine configuration'
          entry :file, ::Gitlab::Config::Entry::Boolean, description: 'Should the created variable be of file type'
          entry :azure_key_vault, Entry::AzureKeyVault::Secret, description: 'Azure Key Vault configuration'

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS, only_one_of_keys: %i[vault azure_key_vault]
            validates :token, type: String, allow_nil: true
          end

          def value
            {
              vault: vault_value,
              azure_key_vault: azure_key_vault_value,
              file: file_value,
              token: token
            }.compact
          end
        end
      end
    end
  end
end
