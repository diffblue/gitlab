# frozen_string_literal: true

module Sbom
  class Source < ApplicationRecord
    enum source_type: {
      dependency_scanning: 0,
      container_scanning: 1
    }

    validates :source_type, presence: true
    validates :source, presence: true, json_schema: { filename: 'sbom_source' }
  end
end
