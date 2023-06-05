# frozen_string_literal: true

module Elastic
  module MigrationCreateIndex
    include Elastic::MigrationHelper

    def migrate
      reindexing_cleanup!

      log "Creating standalone #{document_type} index #{new_index_name}"
      helper.create_standalone_indices(target_classes: [target_class])

    rescue StandardError => e
      log('Failed to create index', error: e.message)
      raise StandardError, e.message
    end

    def completed?
      helper.index_exists?(index_name: new_index_name)
    end

    def target_class
      raise NotImplementedError
    end

    def document_type
      raise NotImplementedError
    end
  end
end
