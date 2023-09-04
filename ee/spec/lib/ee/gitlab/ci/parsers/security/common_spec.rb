# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Common, feature_category: :vulnerability_management do
  describe '#parse!' do
    where(signatures_enabled: [true, false])
    with_them do
      let_it_be(:pipeline) { create(:ci_pipeline) }

      let(:artifact) { build(:ci_job_artifact, :common_security_report) }
      let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, 2.weeks.ago) }
      let(:location) { ::Gitlab::Ci::Reports::Security::Locations::DependencyScanning.new(file_path: 'yarn/yarn.lock', package_version: 'v2', package_name: 'saml2') }
      let(:tracking_data) { nil }

      before do
        allow_next_instance_of(described_class) do |parser|
          allow(parser).to receive(:create_location).and_return(location)
          allow(parser).to receive(:tracking_data).and_return(tracking_data)
        end

        artifact.each_blob { |blob| described_class.parse!(blob, report, signatures_enabled: signatures_enabled) }
      end

      describe 'schema validation' do
        let(:validator_class) { Gitlab::Ci::Parsers::Security::Validators::SchemaValidator }
        let(:parser) { described_class.new('{}', report, signatures_enabled: signatures_enabled, validate: validate) }

        subject(:parse_report) { parser.parse! }

        before do
          allow(validator_class).to receive(:new).and_call_original
        end

        context 'when the validate flag is set as `true`' do
          let(:validate) { true }
          let(:valid?) { false }

          before do
            allow_next_instance_of(validator_class) do |instance|
              allow(instance).to receive(:valid?).and_return(valid?)
              allow(instance).to receive(:errors).and_return(['foo'])
            end

            allow(parser).to receive_messages(create_scanner: true, create_scan: true, collate_remediations: [])
          end

          context 'when the report data is not valid according to the schema' do
            it 'does not try to create report entities' do
              parse_report

              expect(parser).not_to have_received(:create_scanner)
              expect(parser).not_to have_received(:create_scan)
              expect(parser).not_to have_received(:collate_remediations)
            end
          end

          context 'when the report data is valid according to the schema' do
            let(:valid?) { true }

            it 'keeps the execution flow as normal' do
              parse_report

              expect(parser).to have_received(:create_scanner)
              expect(parser).to have_received(:create_scan)
              expect(parser).to have_received(:collate_remediations)
            end
          end
        end
      end

      describe 'parsing remediations' do
        let(:expected_remediation) { create(:ci_reports_security_remediation, diff: 'dG90YWxseSBsZWdpdGltYXRlIGRpZmYsIDEwLzEwIHdvdWxkIGFwcGx5') }

        context 'when one remediation closes two CVEs' do
          it 'assigns it to both findings' do
            vulnerability1 = report.findings[2]
            vulnerability2 = report.findings[3]

            remediation = {
              'fixes' => [
                {
                  'id' => 'vulnerability-3',
                  __oj_introspection: {
                    start_byte: 12245,
                    end_byte: 12289
                  }
                },
                {
                  'id' => 'vulnerability-4',
                  __oj_introspection: {
                    start_byte: 12300,
                    end_byte: 12344
                  }
                }
              ],
              'summary' => 'this remediates the third and fourth vulnerability',
              'diff' => 'dG90YWxseSBsZWdpdGltYXRlIGRpZmYsIDEwLzEwIHdvdWxkIGFwcGx5',
              __oj_introspection: {
                start_byte: 12218,
                end_byte: 12503
              }
            }.deep_stringify_keys

            expect(Gitlab::Json.parse(vulnerability1.raw_metadata).dig('remediations').first).to include remediation
            expect(Gitlab::Json.parse(vulnerability2.raw_metadata).dig('remediations').first).to include remediation
          end
        end

        it 'finds remediation with same id' do
          finding = report.findings[5]

          remediation = {
            'fixes' => [
              {
                'id' => 'vulnerability-6',
                __oj_introspection: {
                  start_byte: 12959,
                  end_byte: 13003
                }
              }
            ],
            'summary' => 'this fixed CVE',
            'diff' => 'dG90YWxseSBsZWdpdGltYXRlIGRpZmYsIDEwLzEwIHdvdWxkIGFwcGx5',
            __oj_introspection: {
              start_byte: 12932,
              end_byte: 13126
            }
          }.deep_stringify_keys

          expect(Gitlab::Json.parse(finding.raw_metadata).dig('remediations').first).to include remediation
          expect(finding.remediations.first.checksum).to eq(expected_remediation.checksum)
        end

        it 'does not assign any remediation to the finding if there exists no related remediation' do
          finding = report.findings[6]

          expect(Gitlab::Json.parse(finding.raw_metadata).dig('remediations').first).to be_nil
          expect(finding.remediations).to match([])
        end
      end

      describe 'parsing scan' do
        it 'returns scan object for each finding' do
          scans = report.findings.map(&:scan)

          expect(scans.map(&:status).all?('success')).to be(true)
          expect(scans.map(&:type).all?('dependency_scanning')).to be(true)
          expect(scans.map(&:start_time).all?('2022-08-10T21:37:00')).to be(true)
          expect(scans.map(&:end_time).all?('2022-08-10T21:38:00')).to be(true)
          expect(scans.size).to eq(7)
          expect(scans.first).to be_a(::Gitlab::Ci::Reports::Security::Scan)
        end
      end
    end
  end
end
