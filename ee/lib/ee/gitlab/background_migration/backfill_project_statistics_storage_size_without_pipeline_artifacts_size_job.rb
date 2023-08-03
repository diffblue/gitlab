# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module BackfillProjectStatisticsStorageSizeWithoutPipelineArtifactsSizeJob
        extend ::Gitlab::Utils::Override

        override :storage_size_components
        def storage_size_components
          if ::Gitlab::CurrentSettings.should_check_namespace_plan?
            super - [:uploads_size]
          else
            super
          end
        end
      end
    end
  end
end
