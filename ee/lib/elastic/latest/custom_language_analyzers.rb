# frozen_string_literal: true

module Elastic
  module Latest
    module CustomLanguageAnalyzers
      class << self
        SUPPORTED_FIELDS = %i[title description].freeze

        def custom_analyzers_mappings(type: :text)
          hash = { properties: {} }

          SUPPORTED_FIELDS.each do |field|
            hash[:properties][field] = {
              fields: custom_analyzers_fields(type: type)
            }
          end

          hash
        end

        def custom_analyzers_fields(type:)
          custom_analyzers_enabled.each_with_object({}) do |analyzer, hash|
            hash[analyzer.to_sym] = {
              analyzer: analyzer,
              type: type
            }
          end
        end

        def add_custom_analyzers_fields(fields)
          search_analyzers = custom_analyzers_search

          return fields if search_analyzers.blank?

          fields_names = fields.map { |m| m[/\w+/] }

          SUPPORTED_FIELDS.each do |field|
            next unless fields_names.include?(field.to_s)

            search_analyzers.each do |analyzer|
              fields << "#{field}.#{analyzer}"
            end
          end

          fields
        end

        private

        def custom_analyzers_enabled
          [].tap do |enabled|
            enabled << 'smartcn' if ::Gitlab::CurrentSettings.elasticsearch_analyzers_smartcn_enabled
            enabled << 'kuromoji' if ::Gitlab::CurrentSettings.elasticsearch_analyzers_kuromoji_enabled
          end
        end

        def custom_analyzers_search
          enabled_analyzers = custom_analyzers_enabled

          [].tap do |analyzers|
            analyzers << 'smartcn' if enabled_analyzers.include?('smartcn') && ::Gitlab::CurrentSettings.elasticsearch_analyzers_smartcn_search
            analyzers << 'kuromoji' if enabled_analyzers.include?('kuromoji') && ::Gitlab::CurrentSettings.elasticsearch_analyzers_kuromoji_search
          end
        end
      end
    end
  end
end
