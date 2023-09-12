# frozen_string_literal: true

class ReindexIssuesToFixLabelIds < Elastic::Migration
  include Search::Elastic::MigrationReindexBasedOnSchemaVersion

  batched!
  batch_size 9_000
  throttle_delay 1.minute

  DOCUMENT_TYPE = Issue
  NEW_SCHEMA_VERSION = 23_09
end
