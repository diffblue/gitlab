# frozen_string_literal: true

module Sbom
  class Source < ApplicationRecord
    enum source_type: {
      dependency_file: 0,
      container_image: 1
    }

    validates :source_type, presence: true
    validates :source, presence: true, json_schema: { filename: 'sbom_source' }
    validates :fingerprint, presence: true
  end
end
