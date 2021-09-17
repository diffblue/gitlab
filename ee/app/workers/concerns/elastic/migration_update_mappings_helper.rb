# frozen_string_literal: true

module Elastic
  module MigrationUpdateMappingsHelper
    def migrate
      if completed?
        log "Skipping updating #{index_name} mapping migration since it is already applied"
        return
      end

      log "Adding #{new_mappings.inspect} to #{index_name} mapping"
      update_mapping!(index_name, { properties: new_mappings })
    end

    def completed?
      helper.refresh_index(index_name: index_name)

      mappings = helper.get_mapping(index_name: index_name)

      # Check if mappings include all new_mappings
      new_mappings.keys.map(&:to_s).to_set.subset?(mappings.keys.to_set)
    end

    private

    def index_name
      raise NotImplementedError
    end

    def new_mappings
      raise NotImplementedError
    end

    def update_mapping!(index_name, mappings)
      helper.update_mapping(index_name: index_name, mappings: mappings)
    end
  end
end
