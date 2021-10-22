# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          module Job
            extend ActiveSupport::Concern
            extend ::Gitlab::Utils::Override

            prepended do
              attributes :dast_configuration, :secrets

              entry :dast_configuration, ::Gitlab::Ci::Config::Entry::DastConfiguration,
                description: 'DAST configuration for this job',
                inherit: false

              entry :secrets, ::Gitlab::Config::Entry::ComposableHash,
                description: 'Configured secrets for this job',
                inherit: false,
                metadata: { composable_class: ::Gitlab::Ci::Config::Entry::Secret }
            end

            EE_ALLOWED_KEYS = %i[dast_configuration secrets].freeze

            override :value
            def value
              super.merge({ dast_configuration: dast_configuration_value, secrets: secrets_value }.compact)
            end

            class_methods do
              extend ::Gitlab::Utils::Override

              override :allowed_keys
              def allowed_keys
                super + EE_ALLOWED_KEYS
              end
            end
          end
        end
      end
    end
  end
end
