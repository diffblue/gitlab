# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestFindings, feature_category: :vulnerability_management do
  describe '#execute' do
    let_it_be(:pipeline) { create(:ci_pipeline) }
    let_it_be(:identifier) { create(:vulnerabilities_identifier) }

    let(:finding_maps) { create_list(:finding_map, 4, identifier_ids: [identifier.id]) }
    let!(:existing_finding) { create(:vulnerabilities_finding, :detected, uuid: finding_maps.first.uuid) }

    subject(:ingest_findings) { described_class.new(pipeline, finding_maps).execute }

    it 'ingests findings' do
      expect { ingest_findings }.to change { Vulnerabilities::Finding.count }.by(3)
    end

    it 'sets the finding and vulnerability ids' do
      expected_finding_ids = Array.new(3) { an_instance_of(Integer) }.unshift(existing_finding.id)
      expected_vulnerability_ids = [existing_finding.vulnerability_id, nil, nil, nil]

      expect { ingest_findings }.to change { finding_maps.map(&:finding_id) }.from(Array.new(4)).to(expected_finding_ids)
                               .and change { finding_maps.map(&:vulnerability_id) }.from(Array.new(4)).to(expected_vulnerability_ids)
    end

    it_behaves_like 'bulk insertable task'
  end
end
