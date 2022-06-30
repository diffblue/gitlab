# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestVulnerabilities::Create do
  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_pipeline, user: user) }
  let(:report_finding) { create(:ci_reports_security_finding) }
  let(:finding_map) { create(:finding_map, :with_finding, report_finding: report_finding) }

  def create_vulnerabilities
    described_class.new(pipeline, [finding_map]).execute
  end

  context 'vulnerability state' do
    context 'when finding has dismissal feedback' do
      let!(:feedback) do
        create(:vulnerability_feedback,
               :dismissal,
               project: finding_map.security_finding.scan.project,
               finding_uuid: finding_map.uuid)
      end

      it 'sets the state of the vulnerability to `dismissed`' do
        create_vulnerabilities
        expect(Vulnerability.last.state).to eq('dismissed')
      end
    end

    context 'when finding has no dismissal feedback' do
      it 'sets the state of the vulnerability to `detected`' do
        create_vulnerabilities
        expect(Vulnerability.last.state).to eq('detected')
      end
    end
  end
end
