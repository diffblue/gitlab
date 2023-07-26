# frozen_string_literal: true

module Sbom
  class Source < ApplicationRecord
    enum source_type: {
      dependency_scanning: 0,
      container_scanning: 1
    }

    validates :source_type, presence: true
    validates :source, presence: true, json_schema: { filename: 'sbom_source' }

    def packager
      source.dig('package_manager', 'name')
    end

    def input_file_path
      source.dig('input_file', 'path')
    end
  end
end
