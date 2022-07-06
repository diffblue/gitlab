# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      # Creates new `Vulnerabilities::FindingLink` records.
      class IngestFindingLinks < AbstractTask
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Vulnerabilities::FindingLink

        private

        def attributes
          finding_maps.flat_map do |finding_map|
            new_links_for(finding_map).map do |link|
              {
                vulnerability_occurrence_id: finding_map.finding_id,
                name: link.name,
                url: link.url
              }
            end
          end
        end

        def new_links_for(finding_map)
          existing_links = existing_finding_links[finding_map.finding_id].to_a
          existing_urls = existing_links.map(&:url)

          finding_map.report_finding.links.reject { |link| existing_urls.include?(link.url) }
        end

        def existing_finding_links
          @existing_finding_links ||= Vulnerabilities::FindingLink.by_finding_id(finding_ids)
                                                                  .group_by(&:vulnerability_occurrence_id)
        end

        def finding_ids
          finding_maps.map(&:finding_id)
        end
      end
    end
  end
end
