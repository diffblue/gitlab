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

          REQUIRED_KEYS = %i[vault].freeze
          ALLOWED_KEYS = (REQUIRED_KEYS + %i[file token]).freeze

          attributes ALLOWED_KEYS

          entry :vault, Entry::Vault::Secret, description: 'Vault secrets engine configuration'
          entry :file, ::Gitlab::Config::Entry::Boolean, description: 'Should the created variable be of file type'

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS, required_keys: REQUIRED_KEYS
            validates :token, type: String, allow_nil: true
          end

          def value
            {
              vault: vault_value,
              file: file_value,
              token: token
            }.compact
          end
        end
      end
    end
  end
end
