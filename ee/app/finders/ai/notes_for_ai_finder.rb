# frozen_string_literal: true

module Ai
  class NotesForAiFinder
    attr_reader :resource, :current_user

    def initialize(current_user, resource:)
      @current_user = current_user
      @resource = resource
    end

    def execute
      return Note.none unless Ability.allowed?(current_user, :read_note, resource)

      limited_notes = resource.notes.without_hidden.by_humans.fresh
      if Ability.allowed?(current_user, :read_internal_note, resource)
        limited_notes
      else
        limited_notes.not_internal
      end
    end
  end
end
