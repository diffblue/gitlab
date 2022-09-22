# frozen_string_literal: true

module Sbom
  class Source < ApplicationRecord
    include IgnorableColumns
    ignore_column :fingerprint, remove_with: '15.7', remove_after: '2022-12-22'

    enum source_type: {
      dependency_scanning: 0,
      container_scanning: 1
    }

    validates :source_type, presence: true
    validates :source, presence: true, json_schema: { filename: 'sbom_source' }
  end
end
