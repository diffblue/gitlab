# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      class HooksExecution < AbstractTask
        def execute
          new_vulnerabilities.each(&:execute_hooks)
        end

        private

        def new_vulnerabilities
          new_finding_maps.map(&:vulnerability_id)
                          .then { Vulnerability.id_in(_1) }
        end

        def new_finding_maps
          finding_maps.select(&:new_record)
        end
      end
    end
  end
end
