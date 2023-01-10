# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestVulnerabilities::Create, feature_category: :vulnerability_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, user: user) }
  let_it_be(:report_finding) { create(:ci_reports_security_finding) }
  let_it_be(:finding_map) { create(:finding_map, :with_finding, report_finding: report_finding) }
  let(:vulnerability) { Vulnerability.last }

  subject { described_class.new(pipeline, [finding_map]).execute }

  context 'vulnerability state' do
    context 'when `deprecate_vulnerabilities_feedback` is disabled' do
      before do
        stub_feature_flags(deprecate_vulnerabilities_feedback: false)
      end

      context 'when finding has dismissal feedback' do
        let!(:feedback) do
          create(:vulnerability_feedback,
                 :dismissal,
                 project: finding_map.security_finding.scan.project,
                 finding_uuid: finding_map.uuid)
        end

        it 'sets the state of the vulnerability to `dismissed`' do
          subject

          expect(vulnerability.state).to eq('dismissed')
        end
      end

      context 'when finding has issue feedback' do
        let!(:feedback) do
          create(:vulnerability_feedback,
                 :issue,
                 project: finding_map.security_finding.scan.project,
                 finding_uuid: finding_map.uuid)
        end

        it 'sets the state of the vulnerability to `detected`' do
          subject

          expect(vulnerability.state).to eq('detected')
        end
      end
    end

    context 'when `deprecate_vulnerabilities_feedback` is enabled' do
      it 'sets the state of the vulnerability to `detected`' do
        subject

        expect(vulnerability.state).to eq('detected')
      end
    end
  end
end
