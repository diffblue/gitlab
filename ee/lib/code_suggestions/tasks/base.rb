# frozen_string_literal: true

module CodeSuggestions
  module Tasks
    class Base
      DEFAULT_CODE_SUGGESTIONS_URL = 'https://codesuggestions.gitlab.com'

      def initialize(params: {}, unsafe_passthrough_params: {})
        @params = params
        @unsafe_passthrough_params = unsafe_passthrough_params
      end

      def endpoint
        base_url = ENV.fetch('CODE_SUGGESTIONS_BASE_URL', DEFAULT_CODE_SUGGESTIONS_URL)

        "#{base_url}/v2/code/#{endpoint_name}"
      end

      def body
        raise NotImplementedError
      end

      private

      attr_reader :params, :unsafe_passthrough_params

      def endpoint_name
        raise NotImplementedError
      end
    end
  end
end
