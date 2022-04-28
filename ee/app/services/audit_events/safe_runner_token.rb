# frozen_string_literal: true

module AuditEvents
  module SafeRunnerToken
    SAFE_TOKEN_LENGTH = 8

    def safe_author(author)
      return author unless author.is_a?(String)

      safe_token_length = SAFE_TOKEN_LENGTH
      if author.start_with?(::RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX)
        safe_token_length += ::RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX.length
      end

      author[0...safe_token_length]
    end
  end
end
