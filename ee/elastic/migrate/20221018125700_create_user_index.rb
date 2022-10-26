# frozen_string_literal: true

class CreateUserIndex < Elastic::Migration
  include Elastic::MigrationHelper

  retry_on_failure

  def migrate
    reindexing_cleanup!

    log "Create standalone #{document_type_plural} index under #{new_index_name}"
    helper.create_standalone_indices(target_classes: [User])
  end

  def completed?
    helper.index_exists?(index_name: new_index_name)
  end

  private

  def document_type
    :user
  end
end
