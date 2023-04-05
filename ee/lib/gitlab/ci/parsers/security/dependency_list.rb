# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class DependencyList
          CONTAINER_IMAGE_PATH_PREFIX = 'container-image:'

          def initialize(project, sha, pipeline)
            @project = project
            @formatter = Formatters::DependencyList.new(project, sha)
            @pipeline = pipeline
          end

          def parse!(json_data, report)
            report_data = Gitlab::Json.parse(json_data)
            parse_dependency_names(report_data, report)
            parse_vulnerabilities(report)
          end

          def parse_dependency_names(report_data, report)
            report_data.fetch('dependency_files', []).each do |file|
              dependencies = file['dependencies']

              next unless dependencies.is_a?(Array)

              dependencies.each do |dependency|
                report.add_dependency(formatter.format(dependency, file['package_manager'], file['path']))
              end
            end
          end

          def parse_vulnerabilities(report)
            vuln_findings = pipeline.vulnerability_findings.by_report_types(%i[container_scanning dependency_scanning])
            vuln_findings.each do |finding|
              dependency = finding.location.dig("dependency")

              next unless dependency

              additional_attrs = { vulnerability_id: finding.vulnerability_id }

              additional_attrs['name'] = finding.name unless finding.metadata['name']

              vulnerability = finding.metadata.merge(additional_attrs)

              report.add_dependency(formatter.format(dependency, '', dependency_path(finding), vulnerability))
            end
          end

          def dependency_path(finding)
            return finding.file if finding.dependency_scanning?

            "#{CONTAINER_IMAGE_PATH_PREFIX}#{finding.image}"
          end

          def apply_licenses!(license_report, report)
            license_report.licenses.each do |license|
              report.apply_license(license)
            end
          end

          private

          attr_reader :formatter, :pipeline, :project
        end
      end
    end
  end
end
