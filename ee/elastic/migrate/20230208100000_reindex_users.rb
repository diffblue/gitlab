# frozen_string_literal: true

class ReindexUsers < Elastic::Migration
  include Elastic::MigrationHelper

  retry_on_failure

  def migrate
    log 'Creating Elastic::ReindexingTask with target User'
    reindex_task = Elastic::ReindexingTask.create!(targets: ['User'])

    log "Created Elastic::ReindexingTask with id #{reindex_task.id}"
  end

  def completed?
    true
  end
end
