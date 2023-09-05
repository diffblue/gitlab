# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module FileMounts
      ROOT_DIR = "/.workspace-data"
      VARIABLES_DIR = "#{ROOT_DIR}/variables".freeze
      VARIABLES_FILE_DIR = "#{VARIABLES_DIR}/file".freeze
      GITLAB_GIT_CREDENTIAL_STORE_FILE = "#{VARIABLES_FILE_DIR}/gl_git_credential_store.sh".freeze
      GITLAB_TOKEN_FILE = "#{VARIABLES_FILE_DIR}/gl_token".freeze
    end
  end
end
