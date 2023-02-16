# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestFindingLinks, feature_category: :vulnerability_management do
  describe '#execute' do
    let(:pipeline) { create(:ci_pipeline) }
    let(:finding_link) { create(:ci_reports_security_link) }
    let(:finding_1) { create(:vulnerabilities_finding) }
    let(:finding_2) { create(:vulnerabilities_finding) }
    let(:report_finding_1) { create(:ci_reports_security_finding, links: [finding_link]) }
    let(:report_finding_2) { create(:ci_reports_security_finding, links: [finding_link]) }
    let(:finding_map_1) { create(:finding_map, finding: finding_1, report_finding: report_finding_1) }
    let(:finding_map_2) { create(:finding_map, finding: finding_2, report_finding: report_finding_2) }
    let(:service_object) { described_class.new(pipeline, [finding_map_1, finding_map_2]) }

    subject(:ingest_finding_links) { service_object.execute }

    before do
      create(:finding_link, finding: finding_2, url: finding_link.url)
    end

    it 'creates finding links for the new records' do
      expect { ingest_finding_links }.to change { Vulnerabilities::FindingLink.count }.by(1)
                                    .and change { finding_1.finding_links.count }.by(1)
    end

    it_behaves_like 'bulk insertable task'
  end
end
