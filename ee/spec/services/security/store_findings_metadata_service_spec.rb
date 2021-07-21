# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::StoreFindingsMetadataService do
  let_it_be(:security_scan) { create(:security_scan) }
  let_it_be(:project) { security_scan.project }
  let_it_be(:security_finding_1) { build(:ci_reports_security_finding) }
  let_it_be(:security_finding_2) { build(:ci_reports_security_finding) }
  let_it_be(:security_finding_3) { build(:ci_reports_security_finding, uuid: nil) }
  let_it_be(:security_scanner) { build(:ci_reports_security_scanner) }
  let_it_be(:report) do
    build(
      :ci_reports_security_report,
      findings: [security_finding_1, security_finding_2, security_finding_3],
      scanners: [security_scanner]
    )
  end

  describe '#execute' do
    let(:service_object) { described_class.new(security_scan, report) }

    subject(:store_findings) { service_object.execute }

    context 'when the given security scan already has findings' do
      before do
        create(:security_finding, scan: security_scan)
      end

      it 'does not create new findings in database' do
        expect { store_findings }.not_to change { Security::Finding.count }
      end
    end

    context 'when the given security scan does not have any findings' do
      before do
        security_scan.findings.delete_all
      end

      it 'creates the security finding entries in database' do
        expect { store_findings }.to change { security_scan.findings.count }.by(2)
                                 .and change { security_scan.findings.first&.severity }.to(security_finding_1.severity.to_s)
                                 .and change { security_scan.findings.first&.confidence }.to(security_finding_1.confidence.to_s)
                                 .and change { security_scan.findings.first&.uuid }.to(security_finding_1.uuid)
                                 .and change { security_scan.findings.last&.uuid }.to(security_finding_2.uuid)
      end

      context 'when the scanners already exist in the database' do
        before do
          create(:vulnerabilities_scanner, project: project, external_id: security_scanner.key)
        end

        it 'does not create new scanner entries in the database' do
          expect { store_findings }.not_to change { Vulnerabilities::Scanner.count }
        end
      end

      context 'when the scanner does not exist in the database' do
        it 'creates new scanner entry in the database' do
          expect { store_findings }.to change { project.vulnerability_scanners.count }.by(1)
        end
      end
    end
  end
end
