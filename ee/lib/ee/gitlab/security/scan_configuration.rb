# frozen_string_literal: true

module EE
  module Gitlab
    module Security
      module ScanConfiguration
        extend ::Gitlab::Utils::Override

        override :available?
        def available?
          super || project.licensed_feature_available?(type)
        end

        override :configuration_path
        def configuration_path
          configurable_scans[type] if can_configure_scan_in_ui?
        end

        private

        def can_configure_scan_in_ui?
          project.licensed_feature_available?(:security_configuration_in_ui)
        end

        def configurable_scans
          strong_memoize(:configurable_scans) do
            {
              sast: project_security_configuration_sast_path(project),
              dast: project_security_configuration_dast_path(project),
              dast_profiles: project_security_configuration_dast_scans_path(project),
              api_fuzzing: project_security_configuration_api_fuzzing_path(project),
              corpus_management: project_security_configuration_corpus_management_path(project)
            }
          end
        end

        override :scans_configurable_in_merge_request
        def scans_configurable_in_merge_request
          super.concat(%i[dependency_scanning container_scanning])
        end
      end
    end
  end
end
