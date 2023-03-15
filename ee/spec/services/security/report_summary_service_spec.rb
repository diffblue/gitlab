# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ReportSummaryService, '#execute', feature_category: :vulnerability_management do
  let_it_be(:pipeline) { create(:ci_pipeline, :success) }

  let_it_be(:build_ds) { create(:ci_build, :success, name: 'dependency_scanning', pipeline: pipeline) }
  let_it_be(:artifact_ds) { create(:ee_ci_job_artifact, :dependency_scanning, job: build_ds) }
  let_it_be(:report_ds) { create(:ci_reports_security_report, type: :dependency_scanning) }
  let_it_be(:scan_ds) { create(:security_scan, scan_type: :dependency_scanning, build: build_ds) }

  let_it_be(:build_sast) { create(:ci_build, :success, name: 'sast', pipeline: pipeline) }
  let_it_be(:artifact_sast) { create(:ee_ci_job_artifact, :sast, job: build_sast) }
  let_it_be(:report_sast) { create(:ci_reports_security_report, type: :sast) }
  let_it_be(:scan_sast) { create(:security_scan, scan_type: :sast, build: build_sast) }

  let_it_be(:build_dast) { create(:ci_build, :success, name: 'dast', pipeline: pipeline) }
  let_it_be(:artifact_dast) { create(:ee_ci_job_artifact, :dast_large_scanned_resources_field, job: build_dast) }
  let_it_be(:report_dast) { create(:ci_reports_security_report, type: :dast) }
  let_it_be(:scan_dast) { create(:security_scan, scan_type: :dast, build: build_dast) }

  let_it_be(:build_cs) { create(:ci_build, :success, name: 'container_scanning', pipeline: pipeline) }
  let_it_be(:artifact_cs) { create(:ee_ci_job_artifact, :container_scanning, job: build_cs) }
  let_it_be(:report_cs) { create(:ci_reports_security_report, type: :container_scanning) }
  let_it_be(:scan_cs) { create(:security_scan, scan_type: :container_scanning, build: build_cs) }

  before(:all) do
    ds_content = File.read(artifact_ds.file.path)
    Gitlab::Ci::Parsers::Security::DependencyScanning.parse!(ds_content, report_ds)
    report_ds.merge!(report_ds)

    sast_content = File.read(artifact_sast.file.path)
    Gitlab::Ci::Parsers::Security::Sast.parse!(sast_content, report_sast)
    report_sast.merge!(report_sast)

    dast_content = File.read(artifact_dast.file.path)
    Gitlab::Ci::Parsers::Security::Dast.parse!(dast_content, report_dast)
    report_dast.merge!(report_dast)

    cs_content = File.read(artifact_cs.file.path)
    Gitlab::Ci::Parsers::Security::ContainerScanning.parse!(cs_content, report_cs)
    report_cs.merge!(report_cs)

    { artifact_cs => report_cs, artifact_dast => report_dast, artifact_ds => report_ds, artifact_sast => report_sast }.each do |artifact, report|
      report.findings.each do |finding|
        create(:security_finding,
              severity: finding.severity,
              confidence: finding.confidence,
              project_fingerprint: finding.project_fingerprint,
              deduplicated: true,
              scan: artifact.job.security_scans.first)
      end
    end
  end

  before do
    stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, dast: true)
  end

  let(:result) do
    described_class.new(
      pipeline,
      selection_information
    ).execute
  end

  context 'Some fields are requested' do
    let(:selection_information) do
      {
        dast: [:scanned_resources_count, :vulnerabilities_count],
        container_scanning: [:vulnerabilities_count]
      }
    end

    it 'returns only the request fields' do
      expect(result).to eq({
        dast: { scanned_resources_count: 26, vulnerabilities_count: 20 },
        container_scanning: { vulnerabilities_count: 8 }
      })
    end
  end

  context 'When some fields are not requested' do
    let(:selection_information) do
      {
        dast: [:scanned_resources_count]
      }
    end

    it 'does not make needless queries' do
      expect(::Security::VulnerabilityCountingService).not_to receive(:new)

      expect_next_instance_of(::Security::ScannedResourcesCountingService, anything, ['dast']) do |service|
        expect(service).to receive(:execute).and_return({})
      end

      result
    end
  end

  context 'when scanned resources are not requested' do
    let(:selection_information) do
      {
        dast: [:vulnerabilities_count],
        container_scanning: [:vulnerabilities_count]
      }
    end

    it 'does not download the artifact' do
      expect(pipeline).not_to receive(:security_reports)

      result
    end
  end

  context 'when the scans is requested' do
    let(:selection_information) { { dast: [:scans] } }

    it 'responds with the scan information' do
      expect(result).to include(dast: { scans: [scan_dast] })
    end
  end

  context 'All fields are requested' do
    let(:selection_information) do
      {
        dast: [:scanned_resources_count, :vulnerabilities_count, :scanned_resources, :scanned_resources_csv_path],
        sast: [:scanned_resources_count, :vulnerabilities_count],
        container_scanning: [:scanned_resources_count, :vulnerabilities_count],
        dependency_scanning: [:scanned_resources_count, :vulnerabilities_count]
      }
    end

    it 'returns the scanned_resources_count' do
      expect(result).to match(a_hash_including(
                                dast: a_hash_including(scanned_resources_count: 26),
                                sast: a_hash_including(scanned_resources_count: 0),
                                container_scanning: a_hash_including(scanned_resources_count: 0),
                                dependency_scanning: a_hash_including(scanned_resources_count: 0)
                              ))
    end

    it 'returns the vulnerability count' do
      expect(result).to match(a_hash_including(
                                dast: a_hash_including(vulnerabilities_count: 20),
                                sast: a_hash_including(vulnerabilities_count: 5),
                                container_scanning: a_hash_including(vulnerabilities_count: 8),
                                dependency_scanning: a_hash_including(vulnerabilities_count: 4)
                              ))
    end

    it 'returns the scanned resources limited to 20' do
      expect(result[:dast][:scanned_resources].length).to eq(20)
    end

    it 'returns the scanned_resources_csv_path' do
      expected_path = Gitlab::Routing.url_helpers.project_security_scanned_resources_path(
        pipeline.project,
        format: :csv,
        pipeline_id: pipeline.id
      )

      expect(result[:dast][:scanned_resources_csv_path]).to eq(expected_path)
    end

    context 'When no security scans ran' do
      let(:pipeline) { create(:ci_pipeline, :success) }

      it 'returns nil' do
        expect(result[:dast]).to be_nil
      end
    end
  end

  context 'When there is a scan but no findings' do
    let_it_be(:pipeline) { create(:ci_pipeline, :success) }

    before do
      build_dast = create(:ci_build, :success, name: 'dast', pipeline: pipeline)

      create(:security_scan, scan_type: :dast, build: build_dast)
    end

    let(:selection_information) do
      {
        dast: [:scanned_resources_count, :vulnerabilities_count],
        sast: [:vulnerabilities_count]
      }
    end

    it 'still returns data for the report ran' do
      expect(result[:dast]).not_to be_nil
      expect(result[:sast]).to be_nil
      expect(result[:container_scanning]).to be_nil
      expect(result[:dependency_scanning]).to be_nil
    end
  end
end
