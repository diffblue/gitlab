# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestIdentifiers, feature_category: :vulnerability_management do
  describe '#execute' do
    let_it_be(:pipeline) { create(:ci_pipeline) }

    let(:existing_fingerprint) { Digest::SHA1.hexdigest('type:id') }
    let(:vulnerability_identifier) { create(:vulnerabilities_identifier, project: pipeline.project, fingerprint: existing_fingerprint, name: 'bar') }
    let(:existing_report_identifier) { create(:ci_reports_security_identifier, external_id: 'id', external_type: 'type') }
    let(:extra_identifiers) { Array.new(21) { |index| create(:ci_reports_security_identifier, external_id: "id-#{index}", external_type: 'type') } }
    let(:identifiers) { extra_identifiers.unshift(existing_report_identifier) }
    let(:expected_fingerprints) { Array.new(19) { |index| Digest::SHA1.hexdigest("type:id-#{index}") }.unshift(existing_fingerprint).sort }

    let(:report_finding) { create(:ci_reports_security_finding, identifiers: identifiers) }
    let(:finding_map) { create(:finding_map, report_finding: report_finding) }
    let(:service_object) { described_class.new(pipeline, [finding_map]) }
    let(:project_identifiers) { pipeline.project.vulnerability_identifiers }

    subject(:ingest_identifiers) { service_object.execute }

    it 'creates new records and updates the existing ones' do
      expect { ingest_identifiers }.to change { project_identifiers.count }.from(1).to(20)
                                   .and change { vulnerability_identifier.reload.name }
    end

    it 'sets the identifier_ids for the finding_map object' do
      expect { ingest_identifiers }.to(
        change { project_identifiers.where(id: finding_map.identifier_ids).pluck(:fingerprint).sort }
          .from([])
          .to(expected_fingerprints))
    end

    it_behaves_like 'bulk insertable task'
  end
end
