# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        module Concerns
          module ScanFinding
            extend ActiveSupport::Concern

            def violates_default_policy_against?(
              target_reports, vulnerabilities_allowed, severity_levels, vulnerability_states, report_types = [])
              return true if scan_removed?(target_reports)

              count = unsafe_findings_count(target_reports, severity_levels, vulnerability_states, report_types)
              count > vulnerabilities_allowed
            end

            def unsafe_findings_uuids(severity_levels, report_types)
              findings.select { |finding| finding.unsafe?(severity_levels, report_types) }.map(&:uuid)
            end

            private

            def unsafe_findings_count(target_reports, severity_levels, vulnerability_states, report_types)
              pipeline_uuids = unsafe_findings_uuids(severity_levels, report_types)
              pipeline_count = count_by_uuid(pipeline_uuids, vulnerability_states)

              new_uuids = pipeline_uuids - target_reports&.unsafe_findings_uuids(severity_levels, report_types).to_a

              pipeline_count += new_uuids.count if vulnerability_states.include?(ApprovalProjectRule::NEWLY_DETECTED)

              pipeline_count
            end

            def count_by_uuid(uuids, states)
              states_without_newly_detected = states.reject { |state| ApprovalProjectRule::NEWLY_DETECTED == state }

              pipeline
                .project
                .vulnerabilities
                .with_findings_by_uuid_and_state(uuids, states_without_newly_detected)
                .count
            end

            def scan_removed?(target_reports)
              (target_reports&.reports&.keys.to_a - reports.keys).any?
            end
          end
        end
      end
    end
  end
end
