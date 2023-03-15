# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::FindingMapCollection, feature_category: :vulnerability_management do
  describe '#each_slice' do
    let_it_be(:security_scan) { create(:security_scan) }
    let_it_be(:security_finding_1) { create(:security_finding, overridden_uuid: '18a77231-f01d-40eb-80f0-de2ddb769a2c', uuid: '78a77231-f01d-40eb-80f0-de2ddb769a2c', scan: security_scan, deduplicated: true) }
    let_it_be(:security_finding_2) { create(:security_finding, uuid: '88a77231-f01d-40eb-80f0-de2ddb769a2c', scan: security_scan, deduplicated: true) }
    let_it_be(:security_finding_3) { create(:security_finding, overridden_uuid: '28a77231-f01d-40eb-80f0-de2ddb769a2c', uuid: '98a77231-f01d-40eb-80f0-de2ddb769a2c', scan: security_scan, deduplicated: true) }

    let(:finding_map_collection) { described_class.new(security_scan) }
    let(:finding_maps) { [] }
    let(:report_findings) { [] }
    let(:finding_pairs) { finding_maps.map { |finding_map| [finding_map.security_finding, finding_map.report_finding] } }
    let(:test_block) { proc { |slice| finding_maps.concat(slice) } }
    let(:expected_finding_pairs) do
      [
        [security_finding_3, report_findings[2]],
        [security_finding_1, report_findings[0]],
        [security_finding_2, report_findings[1]]
      ]
    end

    before do
      create(:security_finding, scan: security_scan, deduplicated: false)

      report_findings << create(:ci_reports_security_finding, uuid: security_finding_1.overridden_uuid)
      report_findings << create(:ci_reports_security_finding, uuid: security_finding_2.uuid)
      report_findings << create(:ci_reports_security_finding, uuid: security_finding_3.overridden_uuid)

      allow(security_scan).to receive(:report_findings).and_return(report_findings)
      allow(finding_maps).to receive(:concat).and_call_original
    end

    context 'when the size argument given' do
      subject(:run_each_slice) { finding_map_collection.each_slice(1, &test_block) }

      it 'calls the given block for each slice by the given size argument' do
        run_each_slice

        expect(finding_maps).to have_received(:concat).exactly(3).times
        expect(finding_pairs).to eq(expected_finding_pairs)
      end
    end
  end
end
