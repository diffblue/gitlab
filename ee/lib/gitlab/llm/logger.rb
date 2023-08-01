# frozen_string_literal: true

module Gitlab
  module Llm
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'llm'
      end

      def self.log_level
        Gitlab::Utils.to_boolean(ENV['LLM_DEBUG']) ? ::Logger::DEBUG : ::Logger::INFO
      end
    end
  end
end
