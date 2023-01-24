# frozen_string_literal: true

module Geo
  class EventLog < ApplicationRecord
    include Geo::Model
    include ::EachBatch

    EVENT_CLASSES = %w[Geo::CacheInvalidationEvent
                       Geo::RepositoryCreatedEvent
                       Geo::RepositoryUpdatedEvent
                       Geo::RepositoryDeletedEvent
                       Geo::RepositoryRenamedEvent
                       Geo::RepositoriesChangedEvent
                       Geo::ResetChecksumEvent
                       Geo::HashedStorageMigratedEvent
                       Geo::HashedStorageAttachmentsEvent
                       Geo::Event].freeze

    belongs_to :cache_invalidation_event,
      class_name: 'Geo::CacheInvalidationEvent',
      foreign_key: :cache_invalidation_event_id

    belongs_to :repository_created_event,
      class_name: 'Geo::RepositoryCreatedEvent',
      foreign_key: :repository_created_event_id

    belongs_to :repository_updated_event,
      class_name: 'Geo::RepositoryUpdatedEvent',
      foreign_key: :repository_updated_event_id

    belongs_to :repository_deleted_event,
      class_name: 'Geo::RepositoryDeletedEvent',
      foreign_key: :repository_deleted_event_id

    belongs_to :repository_renamed_event,
      class_name: 'Geo::RepositoryRenamedEvent',
      foreign_key: :repository_renamed_event_id

    belongs_to :repositories_changed_event,
      class_name: 'Geo::RepositoriesChangedEvent',
      foreign_key: :repositories_changed_event_id

    belongs_to :hashed_storage_migrated_event,
      class_name: 'Geo::HashedStorageMigratedEvent',
      foreign_key: :hashed_storage_migrated_event_id

    belongs_to :hashed_storage_attachments_event,
      class_name: 'Geo::HashedStorageAttachmentsEvent',
      foreign_key: :hashed_storage_attachments_event_id

    belongs_to :reset_checksum_event,
      class_name: 'Geo::ResetChecksumEvent',
      foreign_key: :reset_checksum_event_id

    belongs_to :geo_event,
      class_name: 'Geo::Event',
      foreign_key: :geo_event_id,
      inverse_of: :geo_event_log

    def self.latest_event
      order(id: :desc).first
    end

    def self.next_unprocessed_event
      last_processed = Geo::EventLogState.last_processed
      return first unless last_processed

      find_by('id > ?', last_processed.event_id)
    end

    def self.event_classes
      EVENT_CLASSES.map(&:constantize)
    end

    def self.includes_events
      includes(reflections.keys)
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def event
      repository_created_event ||
        repository_updated_event ||
        repository_deleted_event ||
        repository_renamed_event ||
        repositories_changed_event ||
        hashed_storage_migrated_event ||
        hashed_storage_attachments_event ||
        reset_checksum_event ||
        cache_invalidation_event ||
        geo_event
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def project_id
      event.try(:project_id)
    end
  end
end
