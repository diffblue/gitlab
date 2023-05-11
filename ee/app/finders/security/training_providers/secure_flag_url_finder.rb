# frozen_string_literal: true

module Security
  module TrainingProviders
    class SecureFlagUrlFinder < BaseUrlFinder
      self.reactive_cache_key = ->(finder) { finder.full_url }
      self.reactive_cache_worker_finder = ->(id, *_args) { from_cache(id) }

      ALLOWED_IDENTIFIER_LIST = %w[cwe].freeze

      def calculate_reactive_cache(full_url)
        response = Gitlab::HTTP.try_get(full_url)

        return unless response

        parsed_response = response.parsed_response || {}

        { url: parsed_response["link"] }
      end

      def full_url
        cwe = identifier.split('-').last[/\d+/]
        Gitlab::Utils.append_path(provider.url, "?cwe=#{cwe}#{language_param}")
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
