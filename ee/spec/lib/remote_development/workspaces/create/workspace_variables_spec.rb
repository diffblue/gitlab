# frozen_string_literal: true

require_relative "../../fast_spec_helper"

RSpec.describe ::RemoteDevelopment::Workspaces::Create::WorkspaceVariables,
  feature_category: :remote_development do
  let(:name) { "name" }
  let(:dns_zone) { "example.dns.zone" }
  let(:personal_access_token_value) { "example-pat-value" }
  let(:user_name) { "example.user.name" }
  let(:user_email) { "example@user.email" }
  let(:workspace_id) { 1 }
  let(:git_credential_store_script) do
    <<~SH.chomp
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
  end

  let(:expected_variables) do
    [
      {
        key: "gl_token",
        value: "example-pat-value",
        variable_type: RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_FILE,
        workspace_id: workspace_id
      },
      {
        key: "gl_git_credential_store.sh",
        value: git_credential_store_script,
        variable_type: RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_FILE,
        workspace_id: workspace_id
      },
      {
        key: "GIT_CONFIG_COUNT",
        value: "3",
        variable_type: RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_ENV_VAR,
        workspace_id: workspace_id
      },
      {
        key: "GIT_CONFIG_KEY_0",
        value: "credential.helper",
        variable_type: RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_ENV_VAR,
        workspace_id: workspace_id
      },
      {
        key: "GIT_CONFIG_VALUE_0",
        value: "/.workspace-data/variables/file/gl_git_credential_store.sh",
        variable_type: RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_ENV_VAR,
        workspace_id: workspace_id
      },
      {
        key: "GIT_CONFIG_KEY_1",
        value: "user.name",
        variable_type: RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_ENV_VAR,
        workspace_id: workspace_id
      },
      {
        key: "GIT_CONFIG_VALUE_1",
        value: "example.user.name",
        variable_type: RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_ENV_VAR,
        workspace_id: workspace_id
      },
      {
        key: "GIT_CONFIG_KEY_2",
        value: "user.email",
        variable_type: RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_ENV_VAR,
        workspace_id: workspace_id
      },
      {
        key: "GIT_CONFIG_VALUE_2",
        value: "example@user.email",
        variable_type: RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_ENV_VAR,
        workspace_id: workspace_id
      },
      {
        key: "GL_GIT_CREDENTIAL_STORE_FILE_PATH",
        value: "/.workspace-data/variables/file/gl_git_credential_store.sh",
        variable_type: RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_ENV_VAR,
        workspace_id: workspace_id
      },
      {
        key: "GL_TOKEN_FILE_PATH",
        value: "/.workspace-data/variables/file/gl_token",
        variable_type: RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_ENV_VAR,
        workspace_id: workspace_id
      },
      {
        key: "GL_WORKSPACE_DOMAIN_TEMPLATE",
        value: "${PORT}-name.example.dns.zone",
        variable_type: RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_ENV_VAR,
        workspace_id: workspace_id
      }
    ]
  end

  subject(:variables) do
    described_class.variables(
      name: name,
      dns_zone: dns_zone,
      personal_access_token_value: personal_access_token_value,
      user_name: user_name,
      user_email: user_email,
      workspace_id: workspace_id
    )
  end

  it 'defines correct variables' do
    expect(variables).to eq(expected_variables)
  end
end
