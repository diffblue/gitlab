# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class Compliance < Gitlab::Ci::ProjectConfig::Source
        def content
          strong_memoize(:content) do
            next unless available?
            next unless pipeline_configuration_full_path.present?
            next if pipeline_source_bridge && pipeline_source == :parent_pipeline
            next if pipeline_source == :security_orchestration_policy

            path_file, path_project = pipeline_configuration_full_path.split('@', 2)
            YAML.dump('include' => [{ 'project' => path_project, 'file' => path_file }])
          end
        end

        def internal_include_prepended?
          true
        end

        def source
          :compliance_source
        end

        private

        def pipeline_configuration_full_path
          strong_memoize(:pipeline_configuration_full_path) do
            next unless project

            project.compliance_pipeline_configuration_full_path
          end
        end

        def available?
          project.feature_available?(:evaluate_group_level_compliance_pipeline)
        end
      end
    end
  end
end
