# frozen_string_literal: true

module Gitlab
  module Llm
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'llm'
      end
    end
  end
end
