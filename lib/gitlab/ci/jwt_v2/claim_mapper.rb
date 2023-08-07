# frozen_string_literal: true

module Gitlab
  module Ci
    class JwtV2
      class ClaimMapper
        MAPPER_FOR_CONFIG_SOURCE = {
          repository_source: ClaimMapper::Repository
        }.freeze

        def initialize(project_config, pipeline)
          return unless project_config

          mapper_class = MAPPER_FOR_CONFIG_SOURCE[project_config.source]
          @mapper = mapper_class&.new(project_config, pipeline)
        end

        delegate :ci_config_ref_uri, :ci_config_sha, to: :mapper, allow_nil: true

        def to_h
          {
            ci_config_ref_uri: ci_config_ref_uri,
            ci_config_sha: ci_config_sha
          }
        end

        private

        attr_reader :mapper
      end
    end
  end
end
