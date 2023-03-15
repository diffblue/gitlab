# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::HooksExecution, feature_category: :vulnerability_management do
  describe '#execute' do
    let_it_be(:pipeline) { create(:ci_pipeline) }

    let_it_be(:vulnerabilities) { create_list(:vulnerability, 3) }

    let_it_be(:finding_map_1) { create(:finding_map, vulnerability: vulnerabilities[0], new_record: true) }
    let_it_be(:finding_map_2) { create(:finding_map, vulnerability: vulnerabilities[1], new_record: true) }
    let_it_be(:finding_map_3) { create(:finding_map, vulnerability: vulnerabilities[2]) }

    let!(:service_object) { described_class.new(pipeline, [finding_map_1, finding_map_2, finding_map_3]) }

    subject(:ingest_finding_remediations) { service_object.execute }

    before do
      vulnerabilities.each do |vulnerability|
        allow(vulnerability).to receive(:execute_hooks)
      end

      allow(Vulnerability).to receive(:where).with(id: vulnerabilities[0..1].map(&:id)).and_return(
        [
          vulnerabilities[0],
          vulnerabilities[1]
        ])

      ingest_finding_remediations
    end

    it 'executes the hooks associated with all new vulnerabilities' do
      expect(vulnerabilities[0]).to have_received(:execute_hooks)
      expect(vulnerabilities[1]).to have_received(:execute_hooks)
    end

    it 'does not execute the hooks associated with existing vulnerabilities' do
      expect(vulnerabilities[2]).not_to have_received(:execute_hooks)
    end
  end
end
