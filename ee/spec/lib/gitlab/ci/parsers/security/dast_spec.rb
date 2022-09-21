# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Dast do
  using RSpec::Parameterized::TableSyntax

  describe '#parse!' do
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:artifact) { create(:ee_ci_job_artifact, :dast) }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, 2.weeks.ago) }

    where(:report_format,
          :occurrence_count,
          :identifier_count,
          :evidence_count,
          :scanner_count,
          :scanned_resources_count,
          :last_occurrence_hostname,
          :last_occurrence_method_name,
          :last_occurrence_path,
          :last_occurrence_severity,
          :last_occurrence_confidence,
          :last_occurrence_evidence_summary) do
      :dast                             | 24 | 15 | 2 | 1 | 6 | 'http://goat:8080' | 'GET' | '/WebGoat/plugins/bootstrap/css/bootstrap.min.css' | 'info' | 'low' | nil
      :dast_multiple_sites              | 25 | 15 | 1 | 1 | 0 | 'http://goat:8080' | 'GET' | '/WebGoat/plugins/bootstrap/css/bootstrap.min.css' | 'info' | 'low' | nil
      :dast_14_0_2                      | 1  | 2  | 1 | 1 | 3 | 'http://pancakes' | 'GET' | '/WebGoat/plugins/bootstrap/css/pancakes.css' | 'medium' | 'high' | "Evidence summary"
    end

    with_them do
      let(:artifact) { create(:ee_ci_job_artifact, report_format) }

      before do
        artifact.each_blob { |blob| described_class.parse!(blob, report) }
      end

      it 'parses all identifiers, findings and scanned resources' do
        expect(report.findings.length).to eq(occurrence_count)
        expect(report.identifiers.length).to eq(identifier_count)
        expect(report.scanners.length).to eq(scanner_count)
        expect(report.scanned_resources.length).to eq(scanned_resources_count)
      end

      it 'generates expected location' do
        location = report.findings.last.location
        expect(location).to be_a(::Gitlab::Ci::Reports::Security::Locations::Dast)
        expect(location).to have_attributes(
          hostname: last_occurrence_hostname,
          method_name: last_occurrence_method_name,
          path: last_occurrence_path
        )
      end

      it 'generates expected evidence' do
        evidence = report.findings.last.evidence
        expect(evidence&.data&.dig('summary')).to eq(last_occurrence_evidence_summary)
      end

      describe 'occurrence properties' do
        where(:attribute, :value) do
          :report_type | 'dast'
          :severity | last_occurrence_severity
          :confidence | last_occurrence_confidence
        end

        with_them do
          it 'saves properly occurrence' do
            occurrence = report.findings.last

            expect(occurrence.public_send(attribute)).to eq(value)
          end
        end
      end
    end

    describe 'parses scanned_resources' do
      let(:artifact) { create(:ee_ci_job_artifact, 'dast') }

      before do
        artifact.each_blob { |blob| described_class.parse!(blob, report) }
      end

      let(:raw_json) do
        {
        "vulnerabilities": [],
        "remediations": [],
        "dependency_files": [],
        "scan": {
          "scanned_resources": [
            {
              "method": "GET",
              "type": "url",
              "url": "not a URL"
            }
          ]
        }
      }
      end

      it 'skips invalid URLs' do
        described_class.parse!(raw_json.to_json, report)
        expect(report.scanned_resources).to be_empty
      end

      it 'creates a scanned resource for each URL' do
        expect(report.scanned_resources.length).to eq(6)
        expect(report.scanned_resources.first).to be_a(::Gitlab::Ci::Reports::Security::ScannedResource)
      end
    end
  end
end
