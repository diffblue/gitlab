# frozen_string_literal: true

FactoryBot.define do
  factory :geo_node_status do
    geo_node
    storage_shards { StorageShard.all }

    trait :healthy do
      status_message { nil }
      job_artifacts_synced_missing_on_primary_count { 91 }
      design_repositories_count { 400 }
      design_repositories_failed_count { 3 }
      design_repositories_synced_count { 200 }
      projects_count { 10 }
      repositories_count { 10 }
      repositories_synced_count { 5 }
      repositories_failed_count { 0 }
      wikis_count { 10 }
      wikis_synced_count { 4 }
      wikis_failed_count { 1 }
      repositories_checksummed_count { 600 }
      repositories_checksum_failed_count { 120 }
      repositories_checksum_total_count { 120 }
      wikis_checksummed_count { 585 }
      wikis_checksum_failed_count { 55 }
      wikis_checksum_total_count { 55 }
      repositories_verified_count { 501 }
      repositories_verification_failed_count { 100 }
      repositories_verification_total_count { 100 }
      repositories_checksum_mismatch_count { 15 }
      wikis_verified_count { 499 }
      wikis_verification_failed_count { 99 }
      wikis_verification_total_count { 99 }
      wikis_checksum_mismatch_count { 10 }
      repositories_retrying_verification_count { 25 }
      wikis_retrying_verification_count { 3 }
      repositories_checked_failed_count { 1 }
      last_event_id { 2 }
      last_event_timestamp { Time.now.to_i }
      cursor_last_event_id { 1 }
      cursor_last_event_timestamp { Time.now.to_i }
      last_successful_status_check_timestamp { 2.minutes.ago }
      version { Gitlab::VERSION }
      revision { Gitlab.revision }
      container_repositories_replication_enabled { false }
      design_repositories_replication_enabled { true }
      repositories_replication_enabled { true }
      repository_verification_enabled { true }

      GeoNodeStatus.replicator_class_status_fields.each do |field|
        send(field) { rand(10000) }
      end

      Geo::SecondaryUsageData::PAYLOAD_COUNT_FIELDS.each do |field|
        send(field) { rand(10000) }
      end
    end

    trait :replicated_and_verified do
      design_repositories_failed_count { 0 }
      repositories_failed_count { 0 }
      wikis_failed_count { 0 }
      repositories_verification_failed_count { 0 }
      wikis_verification_failed_count { 0 }
      repositories_checked_failed_count { 0 }

      repositories_synced_count { 10 }
      repositories_checksummed_count { 10 }
      repositories_checksum_total_count { 10 }
      repositories_verified_count { 10 }
      repositories_verification_total_count { 10 }
      repositories_checked_count { 10 }
      wikis_synced_count { 10 }
      wikis_checksummed_count { 10 }
      wikis_checksum_total_count { 10 }
      wikis_verified_count { 10 }
      wikis_verification_total_count { 10 }
      replication_slots_used_count { 10 }
      design_repositories_synced_count { 10 }

      repositories_count { 10 }
      wikis_count { 10 }
      replication_slots_count { 10 }
      design_repositories_count { 10 }

      GeoNodeStatus.replicator_class_status_fields.each do |field|
        send(field) { 10 }
      end
    end

    trait :unhealthy do
      status_message { "Could not connect to Geo node - HTTP Status Code: 401 Unauthorized\nTest" }
    end
  end
end
