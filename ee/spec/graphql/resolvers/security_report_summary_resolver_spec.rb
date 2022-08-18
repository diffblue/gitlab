# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::SecurityReportSummaryResolver do
  include GraphqlHelpers

  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:user) { pipeline.project.first_owner }

  describe '#resolve' do
    before do
      stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, dast: true, security_dashboard: true)
    end

    context 'All fields are requested' do
      let(:lookahead) do
        build_mock_lookahead(expected_selection_info)
      end

      let(:expected_selection_info) do
        {
          dast: [:scanned_resources_count, :vulnerabilities_count, :scans],
          sast: [:scanned_resources_count, :vulnerabilities_count],
          container_scanning: [:scanned_resources_count, :vulnerabilities_count],
          cluster_image_scanning: [:scanned_resources_count, :vulnerabilities_count],
          dependency_scanning: [:scanned_resources_count, :vulnerabilities_count],
          coverage_fuzzing: [:scanned_resources_count, :vulnerabilities_count]
        }
      end

      it 'returns calls the ReportSummaryService' do
        expect_next_instance_of(
          Security::ReportSummaryService,
          pipeline,
          expected_selection_info
        ) do |summary_service|
          expect(summary_service).to receive(:execute).and_return({})
        end

        resolve_security_report_summary
      end

      context 'when the user is not authorized' do
        let_it_be(:user) { create(:user) }

        it 'does not call Security::ReportSummaryService and returns nothing' do
          stub_const('Security::ReportSummaryService', double)

          expect(resolve_security_report_summary).to be_nil
        end
      end
    end

    context 'When lookahead includes :__typename' do
      let(:lookahead) do
        selection_info = {
          dast: [:scanned_resources_count, :vulnerabilities_count, :scans, :__typename],
          sast: [:scanned_resources_count, :vulnerabilities_count, :__typename],
          '__typename': []
        }
        build_mock_lookahead(selection_info)
      end

      let(:expected_selection_info) do
        {
          dast: [:scanned_resources_count, :vulnerabilities_count, :scans],
          sast: [:scanned_resources_count, :vulnerabilities_count]
        }
      end

      it 'does not search for :__typename' do
        expect_next_instance_of(
          Security::ReportSummaryService,
          pipeline,
          expected_selection_info
        ) do |summary_service|
          expect(summary_service).to receive(:execute).and_return({})
        end

        resolve_security_report_summary
      end
    end
  end

  def resolve_security_report_summary
    resolve(described_class, obj: pipeline, lookahead: lookahead, ctx: { current_user: user }, arg_style: :internal)
  end
end

def build_mock_lookahead(structure)
  lookahead_selections = structure.map do |report_type, count_types|
    stub_count_types = count_types.map do |count_type|
      double(count_type, name: count_type)
    end
    double(report_type, name: report_type, selections: stub_count_types)
  end
  double('lookahead', selections: lookahead_selections)
end
