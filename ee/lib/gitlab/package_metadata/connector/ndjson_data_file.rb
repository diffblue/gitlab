# frozen_string_literal: true

require 'csv'

module Gitlab
  module PackageMetadata
    module Connector
      class NdjsonDataFile < BaseDataFile
        def parse(text)
          ::Gitlab::Json.parse(text.force_encoding('UTF-8'))
        rescue JSON::ParserError => e
          Gitlab::AppJsonLogger.warn(class: self.class.name, message: "json parsing error on '#{text}'",
            error: e.message)
          nil
        end

        def self.file_suffix
          'ndjson'
        end
      end
    end
  end
end
