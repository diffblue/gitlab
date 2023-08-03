# frozen_string_literal: true

module Gitlab
  module Ci
    class JwtV2
      class ClaimMapper
        class Repository
          def initialize(project_config, pipeline)
            @project_config = project_config
            @pipeline = pipeline
          end

          def ci_config_ref_uri
            "#{project_config.url}@#{pipeline.source_ref_path}"
          end

          def ci_config_sha
            pipeline.sha
          end

          private

          attr_reader :project_config, :pipeline
        end
      end
    end
  end
end
