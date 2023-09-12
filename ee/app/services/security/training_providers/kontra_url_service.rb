# frozen_string_literal: true

module Security
  module TrainingProviders
    class KontraUrlService < BaseUrlService
      extend ::Gitlab::Utils::Override

      self.reactive_cache_key = ->(service) { service.full_url }
      self.reactive_cache_worker_finder = ->(id, *_args) { from_cache(id) }

      ALLOWED_IDENTIFIER_LIST = %w[CWE cwe].freeze

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

      override :query_params
      def query_params
        params = { cwe: identifier.split('-').last }
        params = params.merge({ language: @language }) if @language
        params
      end

      override :allowed_identifier_list
      def allowed_identifier_list
        ALLOWED_IDENTIFIER_LIST
      end
    end
  end
end
