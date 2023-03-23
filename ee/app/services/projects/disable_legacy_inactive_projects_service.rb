# frozen_string_literal: true

module Projects
  class DisableLegacyInactiveProjectsService
    include ::Gitlab::LoopHelpers

    UPDATE_BATCH_SIZE = 500
    LOOP_LIMIT = 200
    PAUSE_SECONDS = 1 # We don't want to execute too many heavy queries at once

    def execute
      loop_until(limit: LOOP_LIMIT) do
        inactive_public_projects_batch = Project
                                           .public_only
                                           .last_activity_before(1.year.ago)
                                           .with_legacy_open_source_license(true)
                                           .limit(UPDATE_BATCH_SIZE)
        updated_records_count = ProjectSetting
                                  .for_projects(inactive_public_projects_batch)
                                  .update_all(legacy_open_source_license_available: false)

        break if updated_records_count < UPDATE_BATCH_SIZE # Last batch was updated

        sleep(PAUSE_SECONDS)
      end
    end
  end
end
