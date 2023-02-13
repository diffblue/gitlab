# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    class IngestionService
      def self.execute(import_data)
        raise NoMethodError, 'ingestion service is implemented in !108600'
      end
    end
  end
end
