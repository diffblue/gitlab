# frozen_string_literal: true

module EE
  module API
    module Entities
      class EpicIssue < ::API::Entities::Issue
        expose :epic_issue_id,
          documentation: {
            desc: 'ID of the epic-issue relation',
            type: 'integer',
            example: 123
          }
        expose :relative_position,
          documentation: {
            desc: 'Relative position of the issue in the epic tree',
            type: 'integer',
            example: 0
          }
      end
    end
  end
end
