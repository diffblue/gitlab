# frozen_string_literal: true

module Gitlab
  module Llm
    module Templates
      class GenerateCommitMessage
        include Gitlab::Utils::StrongMemoize

        GIT_DIFF_PREFIX_REGEX = /\A@@( -\d+,\d+ \+\d+(,\d+)? )@@/
        MAX_TOKENS = 3_000

        def initialize(merge_request)
          @merge_request = merge_request
        end

        def options(client)
          return {} unless client == ::Gitlab::Llm::OpenAi::Client

          { moderated: true, max_tokens: MAX_TOKENS }
        end

        def to_prompt
          <<~PROMPT
          ```
          #{extracted_diff.truncate_words(2000)}"
          ```

          You are a software developer.
          Lines with additions are prefixed with '+'.
          Lines with deletions are prefixed with '-'.
          Create a clean and comprehensive commit message, do not use conventional commit convention,
          and explain why the change was done for the above code diff.
          Add a short description of why the changes are done after the commit message,
          just describe the changes.
          The title of the merge request is #{merge_request.title}

          Provide the response with a maximum line length of 72 characters.
          Do not include any code in the response.
          PROMPT
        end

        private

        attr_reader :merge_request

        def extracted_diff
          diffs = merge_request.raw_diffs.to_a

          diffs.map { |file| file.diff.sub(GIT_DIFF_PREFIX_REGEX, "Filename: #{file.new_path}") }.join("\n")
        end
      end
    end
  end
end
