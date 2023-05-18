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

            YAML.dump('include' => [{ 'project' => project_path, 'file' => file_path }])
          end
        end

        def internal_include_prepended?
          true
        end

        def source
          :compliance_source
        end

        def url
          namespace, _, project = project_path.partition('/')
          blob = File.join('HEAD', file_path)
          Rails.application.routes.url_helpers.namespace_project_blob_url(namespace, project, blob)
        end

        private

        def file_path
          split_pipeline_configuration_path.first
        end

        def project_path
          split_pipeline_configuration_path.second
        end

        def split_pipeline_configuration_path
          strong_memoize(:split_pipeline_configuration_full_path) do
            pipeline_configuration_full_path.split('@', 2)
          end
        end

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
