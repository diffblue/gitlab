# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestIssueLinks, feature_category: :vulnerability_management do
  describe '#execute' do
    let(:pipeline) { create(:ci_pipeline) }
    let(:report_finding_1) { create(:ci_reports_security_finding) }
    let(:report_finding_2) { create(:ci_reports_security_finding) }
    let(:report_finding_3) { create(:ci_reports_security_finding) }
    let(:finding_map_1) { create(:finding_map, :with_finding, report_finding: report_finding_1) }
    let(:finding_map_2) { create(:finding_map, :new_record, report_finding: report_finding_2) }
    let(:finding_map_3) { create(:finding_map, :new_record, report_finding: report_finding_3) }
    let(:service_object) { described_class.new(pipeline, [finding_map_1, finding_map_2, finding_map_3]) }
    let(:feedback) do
      create(:vulnerability_feedback,
             :issue,
             project: finding_map_2.security_finding.scan.project,
             project_fingerprint: finding_map_2.report_finding.project_fingerprint)
    end

    let(:invalid_feedback) do
      create(:vulnerability_feedback,
             :issue,
             project: finding_map_3.security_finding.scan.project,
             project_fingerprint: finding_map_3.report_finding.project_fingerprint)
    end

    subject(:ingest_issue_links) { service_object.execute }

    before do
      # There will be no issue link created for this record
      # as this is related to an existing finding which means
      # the issue link record should be already created before.
      create(:vulnerability_feedback,
             :issue,
             project: finding_map_1.security_finding.scan.project,
             project_fingerprint: finding_map_1.report_finding.project_fingerprint)

      invalid_feedback.update_column(:issue_id, nil)
    end

    it 'ingests the issue links only for the new records' do
      expect { ingest_issue_links }.to change { Vulnerabilities::IssueLink.for_issue(feedback.issue).count }.by(1)
    end

    it_behaves_like 'bulk insertable task'
  end
end
