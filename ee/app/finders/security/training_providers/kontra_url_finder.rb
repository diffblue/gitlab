# frozen_string_literal: true

module Security
  module TrainingProviders
    class KontraUrlFinder < BaseUrlFinder
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

      def full_url
        Gitlab::Utils.append_path(provider.url, "?cwe=#{identifier_external_id}")
      end
    end
  end
end
