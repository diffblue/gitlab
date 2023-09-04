# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          module Job
            extend ActiveSupport::Concern
            extend ::Gitlab::Utils::Override

            EE_ALLOWED_KEYS = %i[dast_configuration secrets pages_path_prefix].freeze

            prepended do
              attributes :dast_configuration, :secrets, :pages_path_prefix

              entry :dast_configuration, ::Gitlab::Ci::Config::Entry::DastConfiguration,
                description: 'DAST configuration for this job',
                inherit: false

              entry :secrets, ::Gitlab::Config::Entry::ComposableHash,
                description: 'Configured secrets for this job',
                inherit: false,
                metadata: { composable_class: ::Gitlab::Ci::Config::Entry::Secret }

              entry :pages_path_prefix, ::Gitlab::Ci::Config::Entry::PagesPathPrefix,
                inherit: false,
                description: \
                  'Pages path prefix identifier. ' \
                  'This allows to create multiple versions of the same site with different path prefixes'

              validations do
                validates :pages_path_prefix,
                  absence: { message: "can only be used within a `pages` job" },
                  unless: -> { pages_job? }
              end
            end

            class_methods do
              extend ::Gitlab::Utils::Override

              override :allowed_keys
              def allowed_keys
                super + EE_ALLOWED_KEYS
              end
            end

            override :value
            def value
              super.merge({
                dast_configuration: dast_configuration_value,
                secrets: secrets_value,
                pages_path_prefix: pages_path_prefix
              }.compact)
            end
          end
        end
      end
    end
  end
end
