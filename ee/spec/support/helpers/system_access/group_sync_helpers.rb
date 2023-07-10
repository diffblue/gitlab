# frozen_string_literal: true

module SystemAccess
  module GroupSyncHelpers
    def expect_sync_service_call(group_links:, manage_group_ids: nil)
      manage_group_ids = [top_level_group.id, group.id] if manage_group_ids.nil?

      expect(Groups::SyncService).to receive(:new).with(
        top_level_group, user, group_links: group_links, manage_group_ids: manage_group_ids
      ).and_call_original
    end

    def expect_metadata_logging_call(stats)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:stats, stats)
    end
  end
end
