# frozen_string_literal: true

class Geo::BaseRegistry < Geo::TrackingBase
  include BulkInsertSafe
  include EachBatch

  self.abstract_class = true

  include GlobalID::Identification

  def self.pluck_model_ids_in_range(range)
    where(self::MODEL_FOREIGN_KEY => range).pluck(self::MODEL_FOREIGN_KEY)
  end

  def self.pluck_model_foreign_key
    where(nil).pluck(self::MODEL_FOREIGN_KEY)
  end

  def self.model_id_in(ids)
    where(self::MODEL_FOREIGN_KEY => ids)
  end

  def self.model_id_not_in(ids)
    where.not(self::MODEL_FOREIGN_KEY => ids)
  end

  def self.replication_enabled?
    true
  end

  def self.insert_for_model_ids(ids)
    records = ids.map do |id|
      new(self::MODEL_FOREIGN_KEY => id, created_at: Time.zone.now)
    end

    bulk_insert!(records, returns: :ids)
  end

  def self.delete_for_model_ids(ids)
    ids.map do |id|
      delete_worker_class.perform_async(replicator_class.replicable_name, id)
    end
  end

  def self.delete_worker_class
    ::Geo::DestroyWorker
  end

  def self.replicator_class
    self::MODEL_CLASS.replicator_class
  end

  def self.find_registry_differences(range)
    model_primary_key = self::MODEL_CLASS.primary_key.to_sym

    source_ids = self::MODEL_CLASS
                  .replicables_for_current_secondary(range)
                  .pluck(self::MODEL_CLASS.arel_table[model_primary_key])

    tracked_ids = self.pluck_model_ids_in_range(range)

    untracked_ids = source_ids - tracked_ids
    unused_tracked_ids = tracked_ids - source_ids

    [untracked_ids, unused_tracked_ids]
  end

  def self.find_registries_never_attempted_sync(batch_size:, except_ids: [])
    never_attempted_sync
      .model_id_not_in(except_ids)
      .limit(batch_size)
  end

  def self.find_registries_needs_sync_again(batch_size:, except_ids: [])
    needs_sync_again
      .model_id_not_in(except_ids)
      .limit(batch_size)
  end

  def self.has_create_events?
    true
  end

  # Overridden for legacy Geo::ProjectRegistry, Geo::DesignRegistry
  # and Geo::GroupWikiRepositoryRegistry which is not yet verifiable
  # TODO: Remove after
  # https://gitlab.com/gitlab-org/gitlab/-/issues/367926
  # https://gitlab.com/gitlab-org/gitlab/-/issues/391189
  # https://gitlab.com/gitlab-org/gitlab/-/issues/323897
  def self.graphql_mutable?
    true
  end

  # Search for a list of records associated with registries,
  # based on the query given in `query`.
  #
  # @param [String] query term that will search over replicable registries
  def self.with_search(query)
    return all if query.empty?

    where(self::MODEL_FOREIGN_KEY => self::MODEL_CLASS.search(query).limit(1000).pluck_primary_key)
  end

  def model_record_id
    read_attribute(self.class::MODEL_FOREIGN_KEY)
  end
end
