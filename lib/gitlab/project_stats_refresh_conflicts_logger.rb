# frozen_string_literal: true

module Gitlab
  class ProjectStatsRefreshConflictsLogger
    def self.warn_artifact_deletion_during_stats_refresh(project_id:, method:)
      Gitlab::AppLogger.warn(
        message: 'Deleted artifacts undergoing refresh',
        method: method,
        project_id: project_id
      )
    end
  end
end
