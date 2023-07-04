# frozen_string_literal: true

module Gitlab
  module Auth
    module Oidc
      class Config
        class << self
          def options_for(provider_name)
            new(OAuth::Provider.config_for(provider_name))
          end
        end

        def initialize(options)
          @options = options
        end

        def groups_attribute
          options.dig('args', 'client_options', 'gitlab', 'groups_attribute') || 'groups'
        end

        def required_groups
          options.dig('args', 'client_options', 'gitlab', 'required_groups') || []
        end

        def admin_groups
          options.dig('args', 'client_options', 'gitlab', 'admin_groups') || []
        end

        def auditor_groups
          options.dig('args', 'client_options', 'gitlab', 'auditor_groups') || []
        end

        def external_groups
          options.dig('args', 'client_options', 'gitlab', 'external_groups') || []
        end

        private

        attr_reader :options
      end
    end
  end
end
