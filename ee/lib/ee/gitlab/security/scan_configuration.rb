# frozen_string_literal: true

module EE
  module Gitlab
    module Security
      module ScanConfiguration
        def available?
          super || project.licensed_feature_available?(type)
        end

        def configured?
          configured
        end

        def configuration_path
          configurable_scans[type] if available? || type == :corpus_management
        end

        private

        def configurable_scans
          strong_memoize(:configurable_scans) do
            {
              dast: project_security_configuration_dast_path(project),
              dast_profiles: project_security_configuration_dast_scans_path(project),
              api_fuzzing: project_security_configuration_api_fuzzing_path(project),
              corpus_management: (project_security_configuration_corpus_management_path(project) if ::Feature.enabled?(:corpus_management, project, default_enabled: :yaml))
            }.merge(super)
          end
        end
      end
    end
  end
end
