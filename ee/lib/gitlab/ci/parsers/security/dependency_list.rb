# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class DependencyList
          def initialize(project, sha, pipeline)
            @project = project
            @formatter = Formatters::DependencyList.new(project, sha)
            @pipeline = pipeline
          end

          def parse!(json_data, report)
            report_data = Gitlab::Json.parse(json_data)
            parse_dependency_names(report_data, report)
            parse_vulnerabilities(report_data, report)
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

          def parse_vulnerabilities(report_data, report)
            vuln_findings = pipeline.vulnerability_findings.dependency_scanning
            vuln_findings.each do |finding|
              dependency = finding.location.dig("dependency")

              next unless dependency

              file = finding.file
              vulnerability = finding.metadata.merge(vulnerability_id: finding.vulnerability_id)

              report.add_dependency(formatter.format(dependency, '', file, vulnerability))
            end
          end

          def parse_licenses!(json_data, report)
            license_report = ::Gitlab::Ci::Reports::LicenseScanning::Report.parse_from(json_data)
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
