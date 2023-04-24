# frozen_string_literal: true

module EE
  module API
    module Entities
      class EpicIssueLink < Grape::Entity
        expose :id,
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
        expose :epic do |epic_issue_link, _options|
          ::EE::API::Entities::Epic.represent(epic_issue_link.epic, with_reference: true)
        end
        expose :issue, using: ::API::Entities::IssueBasic
      end
    end
  end
end
