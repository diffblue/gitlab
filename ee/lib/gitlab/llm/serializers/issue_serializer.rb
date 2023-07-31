# frozen_string_literal: true

module Gitlab
  module Llm
    module Serializers
      class IssueSerializer
        class << self
          def serialize(issue:, user:, content_limit:)
            new(issue: issue, user: user, content_limit: content_limit).serialize
          end
        end

        def initialize(issue:, user:, content_limit:)
          @issue = issue
          @user = user
          @content_limit = content_limit
        end

        def serialize
          serialized_issue = ::IssueSerializer.new(current_user: user, project: issue.project).represent(issue)
          serialized_issue.merge(issue_comments: notes(issue: issue, user: user,
            notes_limit: (content_limit - serialized_issue.to_json.length)))
        end

        private

        attr_reader :issue, :user, :content_limit

        def notes(issue:, user:, notes_limit:)
          notes = NotesFinder.new(user, target: issue).execute.by_humans
          return notes_to_summarize(notes, notes_limit: notes_limit) if notes.exists?

          []
        end

        def notes_to_summarize(notes, notes_limit:)
          notes_content = []
          sum_of_length = 0

          notes.each_batch do |batch|
            batch.pluck(:id, :note).each do |note| # rubocop: disable CodeReuse/ActiveRecord
              sum_of_length += note[1].size
              break notes_content if sum_of_length >= notes_limit

              notes_content << note[1]
            end
          end

          notes_content
        end
      end
    end
  end
end
