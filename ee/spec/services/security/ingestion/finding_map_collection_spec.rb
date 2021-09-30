# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::FindingMapCollection do
  describe '#each_slice' do
    let(:security_scan) { create(:security_scan) }
    let(:security_findings) { create_list(:security_finding, 3, scan: security_scan, deduplicated: true) }
    let(:report_findings) { [] }
    let(:finding_map_collection) { described_class.new(security_scan) }
    let(:finding_maps) { [] }
    let(:finding_pairs) { finding_maps.map { |finding_map| [finding_map.security_finding, finding_map.report_finding] } }
    let(:test_block) { proc { |slice| finding_maps.concat(slice) } }
    let(:expected_finding_pairs) do
      [
        [security_findings[0], report_findings[0]],
        [security_findings[1], report_findings[1]],
        [security_findings[2], report_findings[2]]
      ]
    end

    before do
      create(:security_finding, scan: security_scan, deduplicated: false)

      security_findings.each { |security_finding| report_findings << create(:ci_reports_security_finding, uuid: security_finding.uuid) }

      allow(security_scan).to receive(:report_findings).and_return(report_findings)
      allow(finding_maps).to receive(:concat).and_call_original
    end

    context 'when the size argument given' do
      subject(:run_each_slice) { finding_map_collection.each_slice(1, &test_block) }

      it 'calls the given block for each slice by the given size argument' do
        run_each_slice

        expect(finding_maps).to have_received(:concat).exactly(3).times
        expect(finding_pairs).to match_array(expected_finding_pairs)
      end
    end
  end
end
