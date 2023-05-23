# frozen_string_literal: true

module API
  module Entities
    class CodeSuggestionsAccessToken < Grape::Entity
      expose :encoded, as: :access_token, documentation: { type: 'string', example: 'eyJ0eXAi...' }
      expose :expires_in, documentation: { type: 'integer', example: 3600 } do |token|
        token.class::EXPIRES_IN
      end
      expose :issued_at, as: :created_at, documentation: { type: 'integer', example: 1684386897 }
    end
  end
end
