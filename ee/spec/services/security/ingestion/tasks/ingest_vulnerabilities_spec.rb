# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestVulnerabilities do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:pipeline) { create(:ci_pipeline, user: user) }
    let_it_be(:identifier) { create(:vulnerabilities_identifier) }

    let(:finding_maps) { create_list(:finding_map, 4) }
    let(:existing_finding) { create(:vulnerabilities_finding, :detected) }

    subject(:ingest_vulnerabilities) { described_class.new(pipeline, finding_maps).execute }

    before do
      finding_maps.first.vulnerability_id = existing_finding.vulnerability_id

      finding_maps.each { |finding_map| finding_map.identifier_ids << identifier.id }
    end

    it 'ingests vulnerabilities' do
      expect { ingest_vulnerabilities }.to change { Vulnerability.count }.by(3)
    end
  end
end
