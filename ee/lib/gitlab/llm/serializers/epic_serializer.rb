# frozen_string_literal: true

module Gitlab
  module Llm
    module Serializers
      class EpicSerializer
        class << self
          def serialize(epic:, user:, content_limit:)
            new(epic: epic, user: user, content_limit: content_limit).serialize
          end
        end

        def initialize(epic:, user:, content_limit:)
          @epic = epic
          @user = user
          @content_limit = content_limit
        end

        def serialize
          serialized_epic = ::EpicSerializer.new(current_user: user).represent(epic)
          serialized_epic.merge(epic_comments: notes(epic: epic, user: user,
            notes_limit: (content_limit - serialized_epic.to_json.length)))
        end

        private

        attr_reader :epic, :user, :content_limit

        def notes(epic:, user:, notes_limit:)
          notes = NotesFinder.new(user, target: epic).execute.by_humans
          notes_to_summarize(notes, notes_limit: notes_limit)
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
