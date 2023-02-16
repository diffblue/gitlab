# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    module Tasks
      class Base
        include Gitlab::Ingestion::BulkInsertableTask

        delegate :import_data, to: :data_map, private: true

        def self.execute(data_map)
          new(data_map).execute
        end

        def initialize(data_map)
          @data_map = data_map
        end

        private

        attr_reader :data_map
      end
    end
  end
end
