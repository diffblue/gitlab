# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module MigrateJobArtifactRegistryToSsf
        class JobArtifactRegistry < Geo::BaseRegistry
          self.table_name = 'job_artifact_registry'
        end

        def perform(start_id, end_id)
          JobArtifactRegistry.where(id: start_id..end_id, success: true).update_all(state: 2)
        end
      end
    end
  end
end
