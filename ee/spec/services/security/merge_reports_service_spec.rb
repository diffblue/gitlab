# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::MergeReportsService, '#execute', feature_category: :vulnerability_management do
  let(:scanner_2) { build(:ci_reports_security_scanner, external_id: 'scanner-2', name: 'Scanner 2') }
  let(:identifier_cwe) { build(:ci_reports_security_identifier, external_id: '789', external_type: 'cwe') }
  let(:identifier_2_primary) { build(:ci_reports_security_identifier, external_id: 'VULN-2', external_type: 'scanner-2') }
  let(:identifier_2_cve) { build(:ci_reports_security_identifier, external_id: 'CVE-2019-456', external_type: 'cve') }

  let(:finding_id_2_loc_1) do
    build(:ci_reports_security_finding,
          identifiers: [identifier_2_primary, identifier_2_cve],
          location: build(:ci_reports_security_locations_sast, start_line: 32, end_line: 34),
          scanner: scanner_2,
          severity: :medium
         )
  end

  context 'ordering reports for dependency scanning analyzers' do
    let(:gemnasium_scanner) { build(:ci_reports_security_scanner, external_id: 'gemnasium', name: 'gemnasium') }
    let(:retire_js_scaner) { build(:ci_reports_security_scanner, external_id: 'retire.js', name: 'Retire.js') }
    let(:bundler_audit_scanner) { build(:ci_reports_security_scanner, external_id: 'bundler_audit', name: 'bundler-audit') }

    let(:identifier_gemnasium) { build(:ci_reports_security_identifier, external_id: 'Gemnasium-b1794c1', external_type: 'gemnasium') }
    let(:identifier_cve) { build(:ci_reports_security_identifier, external_id: 'CVE-2019-123', external_type: 'cve') }
    let(:identifier_npm) { build(:ci_reports_security_identifier, external_id: 'NPM-13', external_type: 'npm') }

    let(:finding_id_1) { build(:ci_reports_security_finding, identifiers: [identifier_gemnasium, identifier_cve, identifier_npm], scanner: gemnasium_scanner, report_type: :dependency_scanning) }
    let(:finding_id_2) { build(:ci_reports_security_finding, identifiers: [identifier_cve], scanner: bundler_audit_scanner, report_type: :dependency_scanning) }
    let(:finding_id_3) { build(:ci_reports_security_finding, identifiers: [identifier_npm], scanner: retire_js_scaner, report_type: :dependency_scanning ) }

    let(:gemnasium_report) do
      build( :ci_reports_security_report,
        type: :dependency_scanning,
        scanners: [gemnasium_scanner],
        findings: [finding_id_1],
        identifiers: finding_id_1.identifiers
      )
    end

    let(:bundler_audit_report) do
      build(
        :ci_reports_security_report,
        type: :dependency_scanning,
        scanners: [bundler_audit_scanner],
        findings: [finding_id_2],
        identifiers: finding_id_2.identifiers
      )
    end

    let(:retirejs_report) do
      build(
        :ci_reports_security_report,
        type: :dependency_scanning,
        scanners: [retire_js_scaner],
        findings: [finding_id_3],
        identifiers: finding_id_3.identifiers
      )
    end

    let(:custom_analyzer_report) do
      build(
        :ci_reports_security_report,
        type: :dependency_scanning,
        scanners: [scanner_2],
        findings: [finding_id_2_loc_1],
        identifiers: finding_id_2_loc_1.identifiers
      )
    end

    context 'when reports are gathered in an unprioritized order' do
      subject(:ds_merged_report) { described_class.new(gemnasium_report, retirejs_report, bundler_audit_report).execute }

      specify { expect(ds_merged_report.scanners.values).to eql([bundler_audit_scanner, retire_js_scaner, gemnasium_scanner]) }
      specify { expect(ds_merged_report.findings.count).to eq(2) }
      specify { expect(ds_merged_report.findings.first.identifiers).to contain_exactly(identifier_cve) }
      specify { expect(ds_merged_report.findings.last.identifiers).to contain_exactly(identifier_npm) }
    end

    context 'when a custom analyzer is completed before the known analyzers' do
      subject(:ds_merged_report) { described_class.new(custom_analyzer_report, retirejs_report, bundler_audit_report).execute }

      specify { expect(ds_merged_report.scanners.values).to eql([bundler_audit_scanner, retire_js_scaner, scanner_2]) }
      specify { expect(ds_merged_report.findings.count).to eq(3) }
      specify { expect(ds_merged_report.findings.last.identifiers).to match_array(finding_id_2_loc_1.identifiers) }
    end

    context 'merging reports step by step' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:gitlab_identifier) { build(:ci_reports_security_identifier, external_id: 'GL-01', external_type: 'gitlab') }
      let(:finding_id_4) { build(:ci_reports_security_finding, identifiers: [identifier_cwe, gitlab_identifier], scanner: gemnasium_scanner, report_type: :dependency_scanning) }
      let(:finding_id_5) { build(:ci_reports_security_finding, identifiers: [identifier_cwe, gitlab_identifier], scanner: retire_js_scaner, report_type: :dependency_scanning) }
      let(:pre_merged_report) { described_class.new(bundler_audit_report, gemnasium_report).execute }

      let(:gemnasium_report) do
        build( :ci_reports_security_report,
          type: :dependency_scanning,
          scanners: [gemnasium_scanner],
          findings: [finding_id_1, finding_id_4],
          identifiers: [finding_id_1.identifiers, finding_id_4.identifiers].flatten
        )
      end

      let(:retirejs_report) do
        build(
          :ci_reports_security_report,
          type: :dependency_scanning,
          scanners: [retire_js_scaner],
          findings: [finding_id_3, finding_id_5],
          identifiers: [finding_id_3.identifiers, finding_id_5.identifiers].flatten
        )
      end

      subject(:merged_report) { described_class.new(pre_merged_report, retirejs_report).execute }

      it 'keeps the finding from `retirejs` as it has higher priority' do
        expect(merged_report.findings).to include(finding_id_5)
      end
    end
  end
end
