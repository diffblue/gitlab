# frozen_string_literal: true

module EE
  module Ci
    module BuildRunnerPresenter
      extend ActiveSupport::Concern

      def secrets_configuration
        secrets.to_h.transform_values do |secret|
          secret['vault']['server'] = vault_server(secret) if secret['vault']
          secret['azure_key_vault']['server'] = azure_key_vault_server(secret) if secret['azure_key_vault']
          secret
        end
      end

      private

      def vault_server(secret)
        @vault_server ||= {
          'url' => variable_value('VAULT_SERVER_URL'),
          'namespace' => variable_value('VAULT_NAMESPACE'),
          'auth' => {
            'name' => 'jwt',
            'path' => variable_value('VAULT_AUTH_PATH', 'jwt'),
            'data' => {
              'jwt' => vault_jwt(secret),
              'role' => variable_value('VAULT_AUTH_ROLE')
            }.compact
          }
        }
      end

      def vault_jwt(secret)
        if id_tokens?
          id_token_var(secret)
        else
          '${CI_JOB_JWT}'
        end
      end

      def id_token_var(secret)
        secret['token'] || "$#{id_tokens.each_key.first}"
      end

      def azure_key_vault_server(secret)
        @azure_key_vault_server ||= {
          'url' => variable_value('AZURE_KEY_VAULT_SERVER_URL'),
          'client_id' => variable_value('AZURE_CLIENT_ID'),
          'tenant_id' => variable_value('AZURE_TENANT_ID'),
          'jwt' => azure_vault_jwt(secret)
        }
      end

      def azure_vault_jwt(secret)
        if id_tokens?
          id_token_var(secret)
        else
          '${CI_JOB_JWT_V2}'
        end
      end
    end
  end
end
