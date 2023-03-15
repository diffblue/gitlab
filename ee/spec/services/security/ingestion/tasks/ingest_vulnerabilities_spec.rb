# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestVulnerabilities, feature_category: :vulnerability_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:pipeline) { create(:ci_pipeline, user: user) }
    let_it_be(:identifier) { create(:vulnerabilities_identifier) }
    let_it_be(:existing_vulnerability) do
      create(:vulnerability, :detected, :with_finding,
                                                resolved_on_default_branch: true, present_on_default_branch: false)
    end

    let_it_be(:resolved_vulnerability) do
      create(:vulnerability, :resolved, :with_finding, resolved_on_default_branch: true, present_on_default_branch:
        false)
    end

    let(:finding_maps) { create_list(:finding_map, 5) }

    subject(:ingest_vulnerabilities) { described_class.new(pipeline, finding_maps).execute }

    before do
      finding_maps.first.vulnerability_id = existing_vulnerability.id
      finding_maps.second.vulnerability_id = resolved_vulnerability.id

      finding_maps.each { |finding_map| finding_map.identifier_ids << identifier.id }
    end

    it 'creates new vulnerabilities' do
      expect { ingest_vulnerabilities }.to change { Vulnerability.count }.by(3)
    end

    it 'marks the existing vulnerability as not resolved on default branch' do
      expect { ingest_vulnerabilities }.to change { existing_vulnerability.reload.resolved_on_default_branch }.to(false)
    end

    it 'creates new vulnerabilities with present_on_default_branch set to true' do
      ingest_vulnerabilities
      expect(Vulnerability.last.present_on_default_branch).to be_truthy
    end

    it 'updates present_on_default_branch to true for existing vulnerabilities' do
      expect { ingest_vulnerabilities }.to change { existing_vulnerability.reload.present_on_default_branch }.to(true)
    end

    context 'when a resolved Vulnerability shows up in a subsequent scan' do
      let(:existing_vulnerabilities) { finding_maps.select(&:vulnerability_id) }

      it 'changes the state to detected' do
        expect(described_class::MarkResolvedAsDetected).to receive(:execute)
          .with(pipeline, existing_vulnerabilities)

        ingest_vulnerabilities
      end
    end
  end
end
