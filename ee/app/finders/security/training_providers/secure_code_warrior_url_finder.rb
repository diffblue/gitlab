# frozen_string_literal: true

module Security
  module TrainingProviders
    class SecureCodeWarriorUrlFinder < BaseUrlFinder
      self.reactive_cache_key = ->(finder) { finder.full_url }
      self.reactive_cache_worker_finder = ->(id, *args) { from_cache(id) }

      ALLOWED_IDENTIFIER_LIST = %w[cwe owasp].freeze
      OWASP_WEB_2017 = %w[A1 A2 A3 A4 A5 A6 A7 A8 A9 A10].freeze
      OWASP_API_2019 = %w[API1 API2 API3 API4 API5 API6 API7 API8 API9 API10].freeze

      def calculate_reactive_cache(full_url)
        response = Gitlab::HTTP.try_get(full_url)
        { url: response.parsed_response["url"] } if response
      end

      def full_url
        Gitlab::Utils.append_path(provider.url, "?Id=gitlab#{mapping_elements}")
      end

      def mapping_elements
        "&MappingList=#{determine_mapping_list}&MappingKey=#{determine_mapping_key}#{language_param}"
      end

      def language_param
        "&LanguageKey=#{@language}" if @language
      end

      def determine_mapping_list
        case external_type
        when "cwe"
          "cwe"
        when "owasp"
          if external_id.in? OWASP_WEB_2017
            "owasp-web-2017"
          elsif external_id.in? OWASP_API_2019
            "owasp-api-2019"
          end
        end
      end

      def determine_mapping_key
        case external_type
        when "cwe"
          identifier.split('-').last
        when "owasp"
          external_id
        end
      end

      def allowed_identifier_list
        ALLOWED_IDENTIFIER_LIST
      end
    end
  end
end
