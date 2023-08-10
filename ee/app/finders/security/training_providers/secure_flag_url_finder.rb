# frozen_string_literal: true

module Security
  module TrainingProviders
    class SecureFlagUrlFinder < BaseUrlFinder
      ALLOWED_IDENTIFIER_LIST = %w[cwe].freeze

      def calculate_reactive_cache(full_url)
        response = Gitlab::HTTP.try_get(full_url)

        return unless response

        parsed_response = response.parsed_response || {}

        { url: parsed_response["link"] }
      end

      def query_string
        cwe = identifier.split('-').last[/\d+/]
        "?cwe=#{cwe}#{language_param}"
      end

      def allowed_identifier_list
        ALLOWED_IDENTIFIER_LIST
      end
    end
  end
end
