# frozen_string_literal: true

module Geo
  # Background migration worker used by ResyncDirectUploadJobArtifactRegistry
  class ResyncDirectUploadJobArtifactRegistryWorker
    include ApplicationWorker
    include GeoQueue

    data_consistency :delayed # Doesn't matter, since this job doesn't touch the main or ci database
    idempotent!

    REGISTRY_TABLE_NAME = 'job_artifact_registry'
    SYNCED_AFTER = '2023-06-22T00:00:00' # 16.1.0 release date
    SYNCED_BEFORE = '2024-02-03T00:00:00' # 6 months after all versions were fixed
    PENDING_STATE_ENUM = 0
    SYNCED_STATE_ENUM = 2

    # Marks artifacts which were synced during a specific time period as pending
    # to be synced.
    #
    # @param [Integer] start is the minimum ID to update
    # @param [Integer] finish is the maximum ID to update
    # @return [void]
    def perform(start, finish)
      query = <<~SQL.squish
        UPDATE #{REGISTRY_TABLE_NAME}
        SET state = #{PENDING_STATE_ENUM}, last_synced_at = NULL
        WHERE state = #{SYNCED_STATE_ENUM}
        AND last_synced_at BETWEEN '#{SYNCED_AFTER}' AND '#{SYNCED_BEFORE}'
        AND id BETWEEN #{start} AND #{finish}
      SQL

      Geo::TrackingBase.connection.execute(query)
    end
  end
end
