# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      class WorkspaceVariables
        VARIABLE_TYPE_ENV_VAR = 0
        VARIABLE_TYPE_FILE = 1
        GIT_CREDENTIAL_STORE_SCRIPT = <<~SH.chomp
          #!/bin/sh
          # This is a readonly store so we can exit cleanly when git attempts a store or erase action
          if [ "$1" != "get" ];
          then
            exit 0
          fi

          if [ -z "${GL_TOKEN_FILE_PATH}" ];
          then
            echo "We could not find the GL_TOKEN_FILE_PATH variable"
            exit 1
          fi
          password=$(cat ${GL_TOKEN_FILE_PATH})

          # The username is derived from the "user.email" configuration item. Ensure it is set.
          echo "username=does-not-matter"
          echo "password=${password}"
          exit 0
        SH

        # @param [String] name
        # @param [String] dns_zone
        # @param [String] personal_access_token_value
        # @param [String] user_name
        # @param [String] user_email
        # @param [Integer] workspace_id
        # @return [Array<Hash>]
        def self.variables(name:, dns_zone:, personal_access_token_value:, user_name:, user_email:, workspace_id:)
          [
            {
              key: File.basename(RemoteDevelopment::Workspaces::FileMounts::GITLAB_TOKEN_FILE),
              value: personal_access_token_value,
              variable_type: VARIABLE_TYPE_FILE,
              workspace_id: workspace_id
            },
            {
              key: File.basename(RemoteDevelopment::Workspaces::FileMounts::GITLAB_GIT_CREDENTIAL_STORE_FILE),
              value: GIT_CREDENTIAL_STORE_SCRIPT,
              variable_type: VARIABLE_TYPE_FILE,
              workspace_id: workspace_id
            },
            {
              key: 'GIT_CONFIG_COUNT',
              value: '3',
              variable_type: VARIABLE_TYPE_ENV_VAR,
              workspace_id: workspace_id
            },
            {
              key: 'GIT_CONFIG_KEY_0',
              value: "credential.helper",
              variable_type: VARIABLE_TYPE_ENV_VAR,
              workspace_id: workspace_id
            },
            {
              key: 'GIT_CONFIG_VALUE_0',
              value: RemoteDevelopment::Workspaces::FileMounts::GITLAB_GIT_CREDENTIAL_STORE_FILE,
              variable_type: VARIABLE_TYPE_ENV_VAR,
              workspace_id: workspace_id
            },
            {
              key: 'GIT_CONFIG_KEY_1',
              value: "user.name",
              variable_type: VARIABLE_TYPE_ENV_VAR,
              workspace_id: workspace_id
            },
            {
              key: 'GIT_CONFIG_VALUE_1',
              value: user_name,
              variable_type: VARIABLE_TYPE_ENV_VAR,
              workspace_id: workspace_id
            },
            {
              key: 'GIT_CONFIG_KEY_2',
              value: "user.email",
              variable_type: VARIABLE_TYPE_ENV_VAR,
              workspace_id: workspace_id
            },
            {
              key: 'GIT_CONFIG_VALUE_2',
              value: user_email,
              variable_type: VARIABLE_TYPE_ENV_VAR,
              workspace_id: workspace_id
            },
            {
              key: 'GL_GIT_CREDENTIAL_STORE_FILE_PATH',
              value: RemoteDevelopment::Workspaces::FileMounts::GITLAB_GIT_CREDENTIAL_STORE_FILE,
              variable_type: VARIABLE_TYPE_ENV_VAR,
              workspace_id: workspace_id
            },
            {
              key: 'GL_TOKEN_FILE_PATH',
              value: RemoteDevelopment::Workspaces::FileMounts::GITLAB_TOKEN_FILE,
              variable_type: VARIABLE_TYPE_ENV_VAR,
              workspace_id: workspace_id
            },
            {
              key: 'GL_WORKSPACE_DOMAIN_TEMPLATE',
              value: "${PORT}-#{name}.#{dns_zone}",
              variable_type: VARIABLE_TYPE_ENV_VAR,
              workspace_id: workspace_id
            }
          ]
        end
      end
    end
  end
end
