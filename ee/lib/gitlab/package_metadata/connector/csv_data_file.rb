# frozen_string_literal: true

require 'csv'

module Gitlab
  module PackageMetadata
    module Connector
      class CsvDataFile < BaseDataFile
        def parse(text)
          CSV.parse(text.force_encoding('UTF-8')).flatten
        rescue CSV::MalformedCSVError => e
          Gitlab::AppJsonLogger.warn(class: self.class.name, message: "csv parsing error on '#{text}'",
            error: e.message)
          nil
        end

        def self.file_suffix
          'csv'
        end
      end
    end
  end
end
