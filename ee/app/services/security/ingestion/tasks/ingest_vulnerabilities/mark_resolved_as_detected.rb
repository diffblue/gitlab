# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      class IngestVulnerabilities
        class MarkResolvedAsDetected < AbstractTask
          def execute
            mark_as_resolved

            finding_maps
          end

          private

          # rubocop:disable CodeReuse/ActiveRecord
          def mark_as_resolved
            ::Vulnerability
              .resolved
              .where(id: resolved_vulnerabilities_ids)
              .update_all(state: ::Vulnerability.states[:detected])
          end

          def resolved_vulnerabilities_ids
            ::Vulnerability.resolved.select(:id).where(id: finding_maps.map(&:vulnerability_id))
          end
          # rubocop:enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
