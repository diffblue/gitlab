# frozen_string_literal: true

class BackfillEpics < Elastic::Migration
  include Elastic::MigrationHelper

  BATCH_SIZE = 1000
  ITERATIONS_PER_RUN = 10

  throttle_delay 1.minute
  batched!
  retry_on_failure

  def migrate
    last_id = max_processed_id || 0
    log 'Indexing epics starting from', id: last_id

    Epic.from_id(last_id, inclusive: false).each_batch(of: BATCH_SIZE) do |epics, index|
      last_id = epics.last.id
      log 'Executing', iteration: index, last_epic_id: last_id

      epics = epics_from_elastic_namespaces(epics) if ::Gitlab::CurrentSettings.elasticsearch_limit_indexing?

      Elastic::ProcessInitialBookkeepingService.track!(*epics)

      break if index >= ITERATIONS_PER_RUN
    end

    set_migration_state(max_processed_id: last_id)
  end

  def completed?
    return true unless Epic.any?

    maximum_epic_id = Epic.maximum(:id)
    log 'Migration completed?', max_processed_id: max_processed_id, maximum_epic_id: maximum_epic_id

    max_processed_id && max_processed_id >= maximum_epic_id
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def epics_from_elastic_namespaces(epics)
    epics_groups = Group.where(id: epics.select(:group_id)).index_by(&:id)

    groups_and_epics_with_elastic_namespace = epics
      .includes(group: :route)
      .group_by(&:group_id)
      .select do |group_id, _|
        ElasticsearchIndexedNamespace.where(namespace_id: epics_groups[group_id].traversal_ids).exists?
      end
    groups_and_epics_with_elastic_namespace.values.flatten
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def max_processed_id
    migration_state[:max_processed_id]
  end
end
