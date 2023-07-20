# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        module AzureKeyVault
          class Secret < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            ALLOWED_KEYS = %i[name version].freeze

            attributes ALLOWED_KEYS

            validations do
              validates :config, type: Hash, allowed_keys: ALLOWED_KEYS
              validates :name, presence: true, type: String
              validates :version, type: String, allow_nil: true
            end

            def value
              {
                name: name,
                version: version
              }
            end
          end
        end
      end
    end
  end
end
