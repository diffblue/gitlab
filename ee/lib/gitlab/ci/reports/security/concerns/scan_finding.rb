# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        module Concerns
          module ScanFinding
            extend ActiveSupport::Concern

            COUNT_BATCH_SIZE = 50

            def violates_default_policy_against?(
              target_reports, vulnerabilities_allowed, severity_levels, vulnerability_states, report_types = [])
              return true if scan_removed?(target_reports)

              count = unsafe_findings_count(target_reports, severity_levels, vulnerability_states, report_types)
              return true if count > vulnerabilities_allowed

              return false if vulnerability_states.include?(ApprovalProjectRule::NEWLY_DETECTED)

              preexisting_count = preexisting_findings_count(
                target_reports, severity_levels, vulnerability_states, report_types
              )
              preexisting_count > vulnerabilities_allowed
            end

            def unsafe_findings_uuids(severity_levels, report_types, vulnerability_states)
              dismissed_uuids = dismissed_uuids(vulnerability_states)

              findings.select do |finding|
                dismissed_uuids.exclude?(finding.uuid) && finding.unsafe?(severity_levels, report_types)
              end.map(&:uuid)
            end

            private

            def dismissed_uuids(vulnerability_states)
              if vulnerability_states.exclude?(ApprovalProjectRule::NEW_DISMISSED)
                ::Vulnerabilities::Read
                  .with_states(:dismissed)
                  .by_uuid(
                    ::Security::Finding
                      .by_scan(pipeline.security_scans)
                      .select(:uuid)
                  ).fetch_uuids
              else
                []
              end
            end

            def unsafe_findings_count(target_reports, severity_levels, vulnerability_states, report_types)
              pipeline_uuids = unsafe_findings_uuids(severity_levels, report_types, [])
              pipeline_count = count_by_uuid(pipeline_uuids, vulnerability_states)

              new_uuids = pipeline_uuids - target_reports&.unsafe_findings_uuids(
                severity_levels, report_types, vulnerability_states
              ).to_a

              if (vulnerability_states & ApprovalProjectRule::NEWLY_DETECTED_STATUSES).any?
                pipeline_count += new_uuids.count
              end

              pipeline_count
            end

            def preexisting_findings_count(target_reports, severity_levels, vulnerability_states, report_types)
              pipeline_uuids = target_reports&.unsafe_findings_uuids(
                severity_levels,
                report_types,
                vulnerability_states).to_a

              count_by_uuid(pipeline_uuids, vulnerability_states)
            end

            def count_by_uuid(uuids, states)
              states_without_newly_detected = states.reject do |state|
                ApprovalProjectRule::NEWLY_DETECTED_STATUSES.include?(state)
              end

              uuids.each_slice(COUNT_BATCH_SIZE).sum do |uuids_batch|
                pipeline
                  .project
                  .vulnerabilities
                  .with_findings_by_uuid_and_state(uuids_batch, states_without_newly_detected)
                  .count
              end
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
