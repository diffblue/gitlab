# frozen_string_literal: true

module CodeSuggestions
  module Tasks
    class Base
      DEFAULT_CODE_SUGGESTIONS_URL = 'https://codesuggestions.gitlab.com'

      def initialize(params)
        @params = params
      end

      def endpoint
        base_url = ENV.fetch('CODE_SUGGESTIONS_BASE_URL', DEFAULT_CODE_SUGGESTIONS_URL)

        "#{base_url}/v2/code/#{endpoint_name}"
      end

      def body
        raise NotImplementedError
      end

      private

      attr_reader :params

      def prefix
        params.dig('current_file', 'content_above_cursor')
      end

      def endpoint_name
        raise NotImplementedError
      end
    end
  end
end
