# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module MigrateJobArtifactRegistryToSsf
        def perform(start_id, end_id)
          # no-op : can't migrate since it depends on the job_artifact_registry.success column and it was removed in  https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103216/
        end
      end
    end
  end
end
