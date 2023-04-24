# frozen_string_literal: true

module EE
  module API
    module Entities
      class GroupPushRule < Grape::Entity
        expose :id, documentation: { type: 'string', example: 2 }
        expose :created_at, documentation: { type: 'dateTime', example: '2020-08-31T15:53:00.073Z' }
        expose :commit_message_regex, documentation: { type: 'string', example: '[a-zA-Z]' }
        expose :commit_message_negative_regex, documentation: { type: 'string', example: '[x+]' }
        expose :branch_name_regex, documentation: { type: 'string', example: '[a-z]' }
        expose :author_email_regex, documentation: { type: 'string', example: '^[A-Za-z0-9.]+@gitlab.com$' }
        expose :file_name_regex, documentation: { type: 'string', example: '(exe)$' }
        expose :deny_delete_tag, documentation: { type: 'boolean' }
        expose :member_check, documentation: { type: 'boolean', example: true }
        expose :prevent_secrets, documentation: { type: 'boolean' }
        expose :max_file_size, documentation: { type: 'integer', example: 100 }
        expose :commit_committer_check,
          if: lambda { |push_rule| push_rule.available?(:commit_committer_check) },
          documentation: { type: 'boolean' }
        expose :reject_unsigned_commits,
          if: lambda { |push_rule| push_rule.available?(:reject_unsigned_commits) },
          documentation: { type: 'boolean' }
      end
    end
  end
end
