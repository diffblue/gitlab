# frozen_string_literal: true

module EE
  module Ci
    module BuildRunnerPresenter
      extend ActiveSupport::Concern

      def secrets_configuration
        secrets.to_h.transform_values do |secret|
          secret['vault']['server'] = vault_server if secret['vault']
          secret
        end
      end

      private

      def vault_server
        @vault_server ||= {
          'url' => variable_value('VAULT_SERVER_URL'),
          'namespace' => variable_value('VAULT_NAMESPACE'),
          'auth' => {
            'name' => 'jwt',
            'path' => variable_value('VAULT_AUTH_PATH', 'jwt'),
            'data' => {
              'jwt' => '${CI_JOB_JWT}',
              'role' => variable_value('VAULT_AUTH_ROLE')
            }.compact
          }
        }
      end
    end
  end
end
