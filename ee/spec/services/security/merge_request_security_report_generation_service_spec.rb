# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::MergeRequestSecurityReportGenerationService, feature_category: :vulnerability_management do
  describe '#execute' do
    let_it_be(:merge_request) { create(:merge_request) }

    let(:service_object) { described_class.new(merge_request, report_type) }

    subject(:report) { service_object.execute }

    context 'when the given report type is invalid' do
      let(:report_type) { 'foo' }

      it 'raises InvalidReportTypeError' do
        expect { report }.to raise_error(described_class::InvalidReportTypeError)
      end
    end

    context 'when the given report type is valid' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:confirmed_finding) { create(:vulnerabilities_finding, :confirmed) }
      let_it_be(:dismissed_finding) { create(:vulnerabilities_finding, :dismissed) }

      let(:new_uuid) { SecureRandom.uuid }
      let(:confirmed_uuid) { confirmed_finding.uuid }
      let(:dismissed_uuid) { dismissed_finding.uuid }

      where(:report_type, :mr_report_method) do
        'sast'                | :compare_sast_reports
        'secret_detection'    | :compare_secret_detection_reports
        'container_scanning'  | :compare_container_scanning_reports
        'dependency_scanning' | :compare_dependency_scanning_reports
        'dast'                | :compare_dast_reports
        'coverage_fuzzing'    | :compare_coverage_fuzzing_reports
        'api_fuzzing'         | :compare_api_fuzzing_reports
      end

      with_them do
        let(:mock_report) do
          {
            status: report_status,
            data: {
              'base_report_created_at' => nil,
              'base_report_out_of_date' => false,
              'head_report_created_at' => '2023-01-18T11:30:01.035Z',
              'added' => [
                {
                  'id' => nil,
                  'name' => 'Test vulnerability 1',
                  'uuid' => new_uuid,
                  'severity' => 'critical'
                },
                {
                  'id' => nil,
                  'name' => 'Test vulnerability 2',
                  'uuid' => confirmed_uuid,
                  'severity' => 'critical'
                }
              ],
              'fixed' => [
                {
                  'id' => nil,
                  'name' => 'Test vulnerability 3',
                  'uuid' => dismissed_uuid,
                  'severity' => 'low'
                }
              ]
            }
          }
        end

        before do
          allow(merge_request).to receive(mr_report_method).with(nil).and_return(mock_report)
        end

        context 'when the report status is `parsing`' do
          let(:report_status) { :parsing }

          it 'returns the report' do
            expect(report).to eq(mock_report)
          end
        end

        context 'when the report status is `parsed`' do
          let(:report_status) { :parsed }
          let(:expected_report) do
            {
              status: report_status,
              data: {
                'base_report_created_at' => nil,
                'base_report_out_of_date' => false,
                'head_report_created_at' => '2023-01-18T11:30:01.035Z',
                'added' => [
                  {
                    'id' => nil,
                    'name' => 'Test vulnerability 1',
                    'uuid' => new_uuid,
                    'severity' => 'critical',
                    'state' => 'detected'
                  },
                  {
                    'id' => nil,
                    'name' => 'Test vulnerability 2',
                    'uuid' => confirmed_uuid,
                    'severity' => 'critical',
                    'state' => 'confirmed'
                  }
                ],
                'fixed' => [
                  {
                    'id' => nil,
                    'name' => 'Test vulnerability 3',
                    'uuid' => dismissed_uuid,
                    'severity' => 'low',
                    'state' => 'dismissed'
                  }
                ]
              }
            }
          end

          it 'returns all the fields along with the calculated state of the findings' do
            expect(report).to eq(expected_report)
            expect(merge_request).to have_received(mr_report_method).with(nil)
          end
        end
      end
    end
  end
end
