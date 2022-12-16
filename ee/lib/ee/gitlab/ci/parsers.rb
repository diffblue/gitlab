# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Parsers
        extend ActiveSupport::Concern

        class_methods do
          def parsers
            super.merge({
                license_scanning: ::Gitlab::Ci::Parsers::LicenseCompliance::LicenseScanning,
                dependency_scanning: ::Gitlab::Ci::Parsers::Security::DependencyScanning,
                container_scanning: ::Gitlab::Ci::Parsers::Security::ContainerScanning,
                cluster_image_scanning: ::Gitlab::Ci::Parsers::Security::ClusterImageScanning,
                dast: ::Gitlab::Ci::Parsers::Security::Dast,
                api_fuzzing: ::Gitlab::Ci::Parsers::Security::Dast,
                coverage_fuzzing: ::Gitlab::Ci::Parsers::Security::CoverageFuzzing,
                metrics: ::Gitlab::Ci::Parsers::Metrics::Generic,
                # 'requirements' artifact will be deprecated soon with https://gitlab.com/groups/gitlab-org/-/epics/9203
                requirements: ::Gitlab::Ci::Parsers::RequirementsManagement::Requirement,
                requirements_v2: ::Gitlab::Ci::Parsers::RequirementsManagement::Requirement
            })
          end
        end
      end
    end
  end
end
