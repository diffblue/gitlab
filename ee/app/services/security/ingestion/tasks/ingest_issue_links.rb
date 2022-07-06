# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      class IngestIssueLinks < AbstractTask
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Vulnerabilities::IssueLink

        private

        def attributes
          new_finding_maps_with_issue_feedback.map do |finding_map|
            {
              issue_id: finding_map.issue_feedback.issue_id,
              vulnerability_id: finding_map.vulnerability_id
            }
          end
        end

        def new_finding_maps_with_issue_feedback
          finding_maps.select(&:new_record)
                      .each(&:issue_feedback) # This iteration is necessary to register BatchLoader.
                      .select { |finding_map| finding_map.issue_feedback.try(:issue_id).present? }
        end
      end
    end
  end
end
