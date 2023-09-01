# frozen_string_literal: true

module EE
  class IssueAiEntity < ::IssueEntity
    expose :issue_comments do |_issue, options|
      options[:resource].notes_with_limit(options[:user], notes_limit: options[:notes_limit])
    end
  end
end
