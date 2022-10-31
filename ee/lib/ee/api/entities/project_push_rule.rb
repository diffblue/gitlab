# frozen_string_literal: true

module EE
  module API
    module Entities
      class ProjectPushRule < Grape::Entity
        extend ::API::Entities::EntityHelpers
        expose :id, documentation: { type: 'integer', example: 2 }
        expose :project_id, documentation: { type: 'integer', example: 3 }
        expose :created_at, documentation: { type: 'date-time', example: '2020-08-31T15:53:00.073Z' }
        expose :commit_message_regex, documentation: { type: 'string', example: 'Fixed \d+\..*' }
        expose :commit_message_negative_regex, documentation: { type: 'string', example: 'ssh\:\/\/' }
        expose :branch_name_regex, documentation: { type: 'string', example: '(feature|hotfix)\/*' }
        expose :deny_delete_tag, documentation: { type: 'boolean', example: true }
        expose :member_check, documentation: { type: 'boolean', example: true }
        expose :prevent_secrets, documentation: { type: 'boolean', example: true }
        expose :author_email_regex, documentation: { type: 'string', example: '@my-company.com$' }
        expose :file_name_regex, documentation: { type: 'string', example: '(jar|exe)$' }
        expose :max_file_size, documentation: { type: 'integer', example: 1024 }
        expose_restricted :commit_committer_check, documentation: { type: 'boolean', example: true }, &:project
        expose_restricted :reject_unsigned_commits, documentation: { type: 'boolean', example: true }, &:project
      end
    end
  end
end
