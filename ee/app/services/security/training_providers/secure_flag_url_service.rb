# frozen_string_literal: true

module Security
  module TrainingProviders
    class SecureFlagUrlService < BaseUrlService
      extend ::Gitlab::Utils::Override

      self.reactive_cache_key = ->(service) { service.full_url }
      self.reactive_cache_worker_finder = ->(id, *_args) { from_cache(id) }

      ALLOWED_IDENTIFIER_LIST = %w[CWE cwe].freeze

      def calculate_reactive_cache(full_url)
        response = Gitlab::HTTP.try_get(full_url)

        return unless response

        parsed_response = response.parsed_response || {}

        { url: parsed_response["link"] }
      end

      override :query_params
      def query_params
        params = {
          cwe: identifier.split('-').last[/\d+/]
        }
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
