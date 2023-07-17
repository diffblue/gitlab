# frozen_string_literal: true

module Gitlab
  module Llm
    module Templates
      class GenerateTestFile
        include Gitlab::Utils::StrongMemoize

        TOTAL_MODEL_TOKEN_LIMIT = 4000
        OUTPUT_TOKEN_LIMIT = (TOTAL_MODEL_TOKEN_LIMIT * 0.25).to_i.freeze

        def initialize(merge_request, path)
          @merge_request = merge_request
          @path = path
        end

        def options(client)
          return {} unless client == ::Gitlab::Llm::OpenAi::Client

          { moderated: true, max_tokens: OUTPUT_TOKEN_LIMIT }
        end

        def to_prompt
          <<~PROMPT
          Write unit tests for #{path} to ensure its proper functioning but only if the file contains code
            """
            #{file_contents}
            """
          PROMPT
        end

        private

        attr_reader :merge_request, :path

        def file_contents
          file = merge_request.diffs.diff_files.find { |file| file.paths.include?(path) }

          file&.blob&.data
        end
      end
    end
  end
end
