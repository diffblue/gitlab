# frozen_string_literal: true

module Zoekt
  class Logger < ::Gitlab::JsonLogger
    def self.file_name_noext
      'zoekt'
    end
  end
end
