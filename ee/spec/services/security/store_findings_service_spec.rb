# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::StoreFindingsService, feature_category: :vulnerability_management do
  let_it_be(:findings_partition_number) { Security::Finding.active_partition_number }
  let_it_be(:security_scan) { create(:security_scan, findings_partition_number: findings_partition_number) }
  let_it_be(:project) { security_scan.project }
  let_it_be(:security_finding_1) { build(:ci_reports_security_finding) }
  let_it_be(:security_finding_2) { build(:ci_reports_security_finding) }
  let_it_be(:security_finding_3) { build(:ci_reports_security_finding) }
  let_it_be(:security_finding_4) { build(:ci_reports_security_finding, uuid: nil) }
  let_it_be(:deduplicated_finding_uuids) { [security_finding_1.uuid, security_finding_3.uuid] }
  let_it_be(:security_scanner) { build(:ci_reports_security_scanner) }
  let_it_be(:report) do
    build(
      :ci_reports_security_report,
      findings: [security_finding_1, security_finding_2, security_finding_3, security_finding_4],
      scanners: [security_scanner]
    )
  end

  describe '#execute' do
    let(:service_object) { described_class.new(security_scan, report, deduplicated_finding_uuids) }

    subject(:store_findings) { service_object.execute }

    context 'when the given security scan already has findings' do
      before do
        create(:security_finding, scan: security_scan)
      end

      it 'returns error message' do
        expect(store_findings).to eq({ status: :error, message: "Findings are already stored!" })
      end

      it 'does not create new findings in database' do
        expect { store_findings }.not_to change(Security::Finding, :count)
      end
    end

    context 'when the given security scan does not have any findings' do
      before do
        security_scan.findings.delete_all
      end

      it 'creates the security finding entries in database' do
        store_findings

        expect(security_scan.findings.reload.as_json(only: [:partition_number, :uuid, :deduplicated]))
          .to match_array(
            [
              {
                "partition_number" => findings_partition_number,
                "uuid" => security_finding_1.uuid,
                "deduplicated" => true
              },
              {
                "partition_number" => findings_partition_number,
                "uuid" => security_finding_2.uuid,
                "deduplicated" => false
              },
              {
                "partition_number" => findings_partition_number,
                "uuid" => security_finding_3.uuid,
                "deduplicated" => true
              }
            ])
      end

      it 'stores raw_source_code_extract from original_data in database' do
        store_findings

        expect(security_scan.findings.reload.as_json(only: :finding_data)).to include(
          a_hash_including(
            "finding_data" => a_hash_including("raw_source_code_extract" => security_finding_1.raw_source_code_extract)
          ),
          a_hash_including(
            "finding_data" => a_hash_including("raw_source_code_extract" => security_finding_2.raw_source_code_extract)
          ),
          a_hash_including(
            "finding_data" => a_hash_including("raw_source_code_extract" => security_finding_3.raw_source_code_extract)
          )
        )
      end

      context 'when the scanners already exist in the database' do
        before do
          create(:vulnerabilities_scanner, project: project, external_id: security_scanner.key)
        end

        it 'does not create new scanner entries in the database' do
          expect { store_findings }.not_to change(Vulnerabilities::Scanner, :count)
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
