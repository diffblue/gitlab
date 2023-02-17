# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::AttachFindingsToVulnerabilities, feature_category: :vulnerability_management do
  describe '#execute' do
    let(:pipeline) { create(:ci_pipeline) }
    let(:finding_maps) { create_list(:finding_map, 3, :new_record) }
    let(:service_object) { described_class.new(pipeline, finding_maps) }
    let(:finding_1) { Vulnerabilities::Finding.find(finding_maps.first.finding_id) }
    let(:finding_2) { Vulnerabilities::Finding.find(finding_maps.second.finding_id) }
    let(:finding_3) { Vulnerabilities::Finding.find(finding_maps.third.finding_id) }
    let(:vulnerability_id_1) { finding_maps.first.vulnerability_id }
    let(:vulnerability_id_2) { finding_maps.second.vulnerability_id }
    let(:vulnerability_id_3) { finding_maps.third.vulnerability_id }

    subject(:attach_findings_to_vulnerabilities) { service_object.execute }

    before do
      finding_maps.third.new_record = false
    end

    it 'associates the findings with vulnerabilities for the new records' do
      expect { attach_findings_to_vulnerabilities }.to change { finding_1.reload.vulnerability_id }.from(nil).to(vulnerability_id_1)
                                                   .and change { finding_2.reload.vulnerability_id }.from(nil).to(vulnerability_id_2)
                                                   .and not_change { finding_3.reload.vulnerability_id }.from(nil)
    end
  end
end
