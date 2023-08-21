# frozen_string_literal: true

module Security
  module TrainingProviders
    class KontraUrlFinder < BaseUrlFinder
      self.reactive_cache_key = ->(finder) { finder.full_url }
      self.reactive_cache_worker_finder = ->(id, *args) { from_cache(id) }

      ALLOWED_IDENTIFIER_LIST = %w[cwe].freeze

      # To improve the authentication/integration
      # https://gitlab.com/gitlab-org/gitlab/-/issues/354070
      BEARER_TOKEN = "sbdMsxcgW2Xs75Q2uHc9FhUCZSEV3fSg"

      def calculate_reactive_cache(full_url)
        response = Gitlab::HTTP.try_get(
          full_url,
          headers: {
            "Authorization" => "Bearer #{BEARER_TOKEN}"
          }
        )
        { url: response.parsed_response["link"] } if response
      end

      def full_url
        Gitlab::Utils.append_path(provider.url, "?cwe=#{identifier.split('-').last}#{language_param}")
      end

      def language_param
        "&language=#{@language}" if @language
      end

      def allowed_identifier_list
        ALLOWED_IDENTIFIER_LIST
      end
    end
  end
end
