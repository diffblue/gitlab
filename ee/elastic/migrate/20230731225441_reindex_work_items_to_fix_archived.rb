# frozen_string_literal: true

class ReindexWorkItemsToFixArchived < Elastic::Migration
  include Search::Elastic::MigrationReindexBasedOnSchemaVersion

  batched!
  batch_size 9_000
  throttle_delay 1.minute

  DOCUMENT_TYPE = WorkItem
  NEW_SCHEMA_VERSION = 23_08
  UPDATE_BATCH_SIZE = 100
end
