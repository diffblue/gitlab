# frozen_string_literal: true

module Security
  module TrainingProviders
    class SecureCodeWarriorUrlService < BaseUrlService
      extend ::Gitlab::Utils::Override

      self.reactive_cache_key = ->(service) { service.full_url }
      self.reactive_cache_worker_finder = ->(id, *_args) { from_cache(id) }

      ALLOWED_IDENTIFIER_LIST = %w[CWE cwe owasp].freeze
      OWASP_WEB_2017 = %w[A1 A2 A3 A4 A5 A6 A7 A8 A9 A10].freeze
      OWASP_API_2019 = %w[API1 API2 API3 API4 API5 API6 API7 API8 API9 API10].freeze

      def calculate_reactive_cache(full_url)
        response = Gitlab::HTTP.try_get(full_url)
        { url: response.parsed_response["url"] } if response
      end

      override :query_params
      def query_params
        params = {
          'Id' => 'gitlab',
          'MappingList' => mapping_list,
          'MappingKey' => mapping_key
        }
        params = params.merge({ 'LanguageKey' => @language }) if @language
        params
      end

      def mapping_list
        case external_type.downcase
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

      def mapping_key
        case external_type.downcase
        when "cwe"
          identifier.split('-').last
        when "owasp"
          external_id
        end
      end

      override :allowed_identifier_list
      def allowed_identifier_list
        ALLOWED_IDENTIFIER_LIST
      end
    end
  end
end
