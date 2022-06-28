# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      class IngestVulnerabilities
        class MarkResolvedAsDetected < AbstractTask
          include Gitlab::Utils::StrongMemoize

          def execute
            mark_as_resolved

            finding_maps
          end

          private

          # rubocop:disable CodeReuse/ActiveRecord
          def mark_as_resolved
            ApplicationRecord.transaction do
              create_state_transitions(resolved_vulnerabilities_ids)

              ::Vulnerability
                .resolved
                .where(id: resolved_vulnerabilities_ids)
                .update_all(state: ::Vulnerability.states[:detected])
            end
          end

          def resolved_vulnerabilities_ids
            strong_memoize(:resolved_vulnerabilities_ids) do
              ::Vulnerability.resolved.select(:id).where(id: finding_maps.map(&:vulnerability_id))
            end
          end
          # rubocop:enable CodeReuse/ActiveRecord

          def create_state_transitions(vulnerability_ids)
            vulnerability_ids.each do |vulnerability_id|
              create_state_transition_for(vulnerability_id)
            end
          end

          def create_state_transition_for(vulnerability_id)
            ::Vulnerabilities::StateTransition.create!(
              vulnerability: vulnerability_id,
              from_state: ::Vulnerability.states[:resolved],
              to_state: ::Vulnerability.states[:detected]
            )
          end
        end
      end
    end
  end
end
