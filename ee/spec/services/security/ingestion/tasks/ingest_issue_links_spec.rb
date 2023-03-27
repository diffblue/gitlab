# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestIssueLinks, feature_category: :vulnerability_management do
  describe '#execute' do
    let_it_be(:pipeline) { create(:ci_pipeline) }
    let_it_be(:compare_key) { 'foo' }
    let_it_be(:project_fingerprint) { Digest::SHA1.hexdigest('foo') } # rubocop:disable Fips/SHA1 (This is used to match existing function with the report finding)
    let_it_be(:project) { create(:project) }
    let_it_be(:security_scan) { create(:security_scan, project: project) }
    let_it_be(:security_finding_1) { create(:security_finding, scan: security_scan) }
    let_it_be(:security_finding_2) { create(:security_finding, scan: security_scan) }
    let_it_be(:security_finding_3) { create(:security_finding, scan: security_scan) }
    let_it_be(:report_finding_1) { create(:ci_reports_security_finding, compare_key: compare_key) }
    let_it_be(:report_finding_2) { create(:ci_reports_security_finding, compare_key: compare_key) }
    let_it_be(:report_finding_3) { create(:ci_reports_security_finding, compare_key: compare_key) }

    let(:finding_map_1) do
      create(:finding_map,
             :with_finding,
             security_finding: security_finding_1,
             report_finding: report_finding_1)
    end

    let(:finding_map_2) do
      create(:finding_map,
             :new_record,
             security_finding: security_finding_2,
             report_finding: report_finding_2)
    end

    let(:finding_map_3) do
      create(:finding_map,
             :new_record,
             security_finding: security_finding_3,
             report_finding: report_finding_3)
    end

    let(:service_object) { described_class.new(pipeline, [finding_map_1, finding_map_2, finding_map_3]) }
    let(:feedback) do
      create(:vulnerability_feedback,
             :issue,
             project: finding_map_2.security_finding.scan.project,
             finding_uuid: finding_map_2.uuid,
             project_fingerprint: project_fingerprint)
    end

    let(:invalid_feedback) do
      create(:vulnerability_feedback,
             :issue,
             project: finding_map_3.security_finding.scan.project,
             finding_uuid: finding_map_3.uuid,
             project_fingerprint: project_fingerprint)
    end

    subject(:ingest_issue_links) { service_object.execute }

    before do
      # There will be no issue link created for this record
      # as this is related to an existing finding which means
      # the issue link record should be already created before.
      create(:vulnerability_feedback,
             :issue,
             project: finding_map_1.security_finding.scan.project,
             finding_uuid: finding_map_1.uuid,
             project_fingerprint: project_fingerprint)

      invalid_feedback.update_column(:issue_id, nil)
    end

    it 'ingests the issue links only for the new records' do
      expect { ingest_issue_links }.to change { Vulnerabilities::IssueLink.for_issue(feedback.issue).count }.by(1)
    end

    it_behaves_like 'bulk insertable task'
  end
end
