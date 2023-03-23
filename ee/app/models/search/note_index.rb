# frozen_string_literal: true

module Search
  class NoteIndex < Index
    def self.indexed_class
      ::Note
    end
  end
end
