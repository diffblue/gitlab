# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      class IngestVulnerabilities
        # Creates new vulnerability records in database for the given
        # findings map by using a single database query.
        class Create < AbstractTask
          include Gitlab::Ingestion::BulkInsertableTask

          self.model = Vulnerability
          self.uses = :id

          private

          def after_ingest
            return_data.each_with_index do |vulnerability_id, index|
              finding_map = finding_maps[index]

              finding_map.vulnerability_id = vulnerability_id
              finding_map.new_record = true
            end
          end

          def attributes
            if Feature.enabled?(:deprecate_vulnerabilities_feedback, @project)
              finding_maps.map { |finding_map| attributes_for_finding(finding_map.report_finding) }
            else
              finding_maps.map { |finding_map| attributes_for(finding_map.report_finding, dismissal_feedback[finding_map.uuid]) }
            end
          end

          def attributes_for_finding(report_finding)
            {
              author_id: pipeline.user_id,
              project_id: pipeline.project_id,
              title: report_finding.name.to_s.truncate(::Issuable::TITLE_LENGTH_MAX),
              state: :detected, # this will be detected because if there is any interaction for dismissal for finding, there will be vulnerability already
              severity: report_finding.severity,
              confidence: report_finding.confidence,
              report_type: report_finding.report_type,
              present_on_default_branch: true
            }
          end

          # We will remove this code after deprecating feedback https://gitlab.com/gitlab-org/gitlab/-/issues/324899
          def attributes_for(report_finding, feedback)
            {
              author_id: pipeline.user_id,
              project_id: pipeline.project_id,
              title: report_finding.name.to_s.truncate(::Issuable::TITLE_LENGTH_MAX),
              state: vulnerability_state(feedback),
              severity: report_finding.severity,
              confidence: report_finding.confidence,
              report_type: report_finding.report_type,
              dismissed_at: feedback&.created_at,
              dismissed_by_id: feedback&.author_id,
              present_on_default_branch: true
            }
          end

          # We will remove this code after deprecating feedback https://gitlab.com/gitlab-org/gitlab/-/issues/324899
          def dismissal_feedback
            @dismissal_feedback ||= Vulnerabilities::Feedback.by_finding_uuid(finding_uuids).index_by(&:finding_uuid)
          end

          def finding_uuids
            finding_maps.map(&:uuid)
          end

          # We will remove this code after deprecating feedback https://gitlab.com/gitlab-org/gitlab/-/issues/324899
          def vulnerability_state(feedback)
            case feedback&.feedback_type
            when "dismissal"
              :dismissed
            else
              :detected
            end
          end
        end
      end
    end
  end
end
