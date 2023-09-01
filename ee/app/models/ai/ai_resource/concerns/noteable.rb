# frozen_string_literal: true

module Ai
  module AiResource
    module Concerns
      module Noteable
        extend ActiveSupport::Concern
        def notes_with_limit(user, notes_limit:)
          limited_notes = Ai::NotesForAiFinder.new(user, resource: resource).execute

          return [] if limited_notes.empty?

          notes_content = []
          sum_of_length = 0

          limited_notes.each_batch(of: 500) do |batch|
            batch.fresh.pluck(:note).each do |note| # rubocop: disable CodeReuse/ActiveRecord
              sum_of_length += note.size
              break notes_content if sum_of_length >= notes_limit

              notes_content << note
            end
            break notes_content if sum_of_length >= notes_limit
          end

          notes_content
        end
      end
    end
  end
end
