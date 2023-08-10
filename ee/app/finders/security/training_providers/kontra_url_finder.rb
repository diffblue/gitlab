# frozen_string_literal: true

module Security
  module TrainingProviders
    class KontraUrlFinder < BaseUrlFinder
      ALLOWED_IDENTIFIER_LIST = %w[cwe].freeze

      def calculate_reactive_cache(full_url)
        bearer_token = "sbdMsxcgW2Xs75Q2uHc9FhUCZSEV3fSg" # To improve the authentication/integration https://gitlab.com/gitlab-org/gitlab/-/issues/354070
        response = Gitlab::HTTP.try_get(
          full_url,
          headers: {
            "Authorization" => "Bearer #{bearer_token}"
          }
        )
        { url: response.parsed_response["link"] } if response
      end

      def query_string
        "?cwe=#{identifier.split('-').last}#{language_param}"
      end

      def allowed_identifier_list
        ALLOWED_IDENTIFIER_LIST
      end
    end
  end
end
