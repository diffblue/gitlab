# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Reports
        module Security
          module Reports
            extend ::Gitlab::Utils::Override

            private

            override :unsafe_findings_count
            def unsafe_findings_count(target_reports, severity_levels, vulnerability_states, report_types)
              pipeline_uuids = unsafe_findings_uuids(severity_levels, report_types)
              pipeline_count = count_by_uuid(pipeline_uuids, vulnerability_states)

              new_uuids = pipeline_uuids - target_reports&.unsafe_findings_uuids(severity_levels, report_types).to_a

              if vulnerability_states.include?(ApprovalProjectRule::NEWLY_DETECTED)
                pipeline_count += new_uuids.count
              end

              pipeline_count
            end

            def count_by_uuid(uuids, states)
              pipeline.project.vulnerabilities.with_findings_by_uuid_and_state(uuids, states.reject { |state| ApprovalProjectRule::NEWLY_DETECTED == state }).count
            end
          end
        end
      end
    end
  end
end
