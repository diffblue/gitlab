# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content
            class Compliance < Source
              def content
                strong_memoize(:content) do
                  next unless available?
                  next unless pipeline_configuration_full_path.present?
                  next if command.bridge

                  path_file, path_project = pipeline_configuration_full_path.split('@', 2)
                  YAML.dump('include' => [{ 'project' => path_project, 'file' => path_file }])
                end
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
    end
  end
end
