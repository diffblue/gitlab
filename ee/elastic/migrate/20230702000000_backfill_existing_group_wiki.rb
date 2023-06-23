# frozen_string_literal: true

class BackfillExistingGroupWiki < Elastic::Migration
  include Elastic::MigrationHelper

  ELASTIC_TIMEOUT = '5m'

  batch_size 200
  batched!
  throttle_delay 5.minutes
  retry_on_failure

  def migrate
    set_migration_state(max_group_id: max_group_id) unless migration_state.has_key?(:max_group_id)
    return if completed?

    log "Executing iteration for next #{batch_size} groups starting from", group_id: max_processed_group_id
    last_id = max_processed_group_id

    group_wiki_repository_to_index.each.with_index do |gwr, idx|
      last_id = gwr.group_id
      ElasticWikiIndexerWorker.perform_in(idx, last_id, 'Group', { force: true })
    end
    set_migration_state(max_processed_group_id: last_id)
  end

  def completed?
    unless max_group_id
      log 'GroupWikiRepository is empty', completed: true
      return true
    end

    if max_processed_group_id < max_group_id
      log 'Indexing is in progress', last_group_id: max_processed_group_id, completed: false
      return false
    end

    log 'All Groups needed to be indexed are indexed', last_group_id: max_processed_group_id, completed: true
    true
  end

  private

  def max_processed_group_id
    migration_state[:max_processed_group_id] || 0
  end

  def max_group_id
    migration_state[:max_group_id] || GroupWikiRepository.last&.group_id
  end

  def group_wiki_repository_to_index
    GroupWikiRepository.where('group_id > ?', max_processed_group_id).order(:group_id).limit(batch_size)  # rubocop:disable CodeReuse/ActiveRecord(RuboCop)
  end
end
