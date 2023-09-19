# frozen_string_literal: true

module CodeSuggestions
  class InstructionsExtractor
    COMMENT_SIGNS = %r{^[ \t]*(?:#|//|--)+[ \t]*}

    def initialize(content, first_line_regex)
      @content = content
      @first_line_regex = first_line_regex
    end

    def self.extract(content, first_line_regex)
      new(content, first_line_regex).extract
    end

    def extract
      lines = content.to_s.lines
      comment_block = []

      lines.reverse_each do |line|
        break unless line.strip.match?(COMMENT_SIGNS)

        comment_block.unshift(line)
      end

      # Matches the first comment line requirements
      return {} unless comment_block.first&.match(first_line_regex)

      # lines before the last comment block
      prefix = lines[0...-comment_block.length].join("")

      instruction = comment_block.map { |line| line.gsub!(COMMENT_SIGNS, '') }.join("").strip

      # TODO: Remove when `code_suggestions_no_comment_prefix` feature flag
      # is removed https://gitlab.com/gitlab-org/gitlab/-/issues/424879
      instruction.gsub!(/GitLab Duo Generate:\s?/, '')

      {
        prefix: prefix,
        instruction: instruction
      }
    end

    private

    attr_reader :content, :first_line_regex
  end
end
