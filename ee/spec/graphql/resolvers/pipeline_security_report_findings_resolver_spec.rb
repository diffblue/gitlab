# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::PipelineSecurityReportFindingsResolver, feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline, reload: true) { create(:ci_pipeline, :success, project: project) }

  describe '#resolve' do
    subject(:resolve_query) { resolve(described_class, obj: pipeline, args: params) }

    let_it_be(:low_vulnerability_finding) { build(:vulnerabilities_finding, severity: :low, report_type: :dast, project: project) }
    let_it_be(:critical_vulnerability_finding) { build(:vulnerabilities_finding, severity: :critical, report_type: :sast, project: project) }
    let_it_be(:high_vulnerability_finding) { build(:vulnerabilities_finding, severity: :high, report_type: :container_scanning, project: project) }

    let(:params) { {} }

    before do
      allow_next_instance_of(Security::PipelineVulnerabilitiesFinder) do |instance|
        allow(instance).to receive_message_chain(:execute, :findings).and_return(returned_findings)
      end
    end

    describe 'utilized finder class' do
      let(:mock_report) { instance_double(Gitlab::Ci::Reports::Security::AggregatedReport, findings: []) }
      let(:mock_pure_finder) { instance_double(Security::PureFindingsFinder, execute: [], available?: pure_finder_available?) }
      let(:mock_deprecated_finder) { instance_double(Security::PipelineVulnerabilitiesFinder, execute: mock_report) }

      before do
        allow(Security::PureFindingsFinder).to receive(:new).and_return(mock_pure_finder)
        allow(Security::PipelineVulnerabilitiesFinder).to receive(:new).and_return(mock_deprecated_finder)
      end

      context 'when the pure findings finder is available' do
        let(:pure_finder_available?) { true }

        it 'uses the pure findings finder' do
          resolve_query

          expect(mock_pure_finder).to have_received(:execute)
          expect(mock_deprecated_finder).not_to have_received(:execute)
        end
      end

      context 'when the pure findings finder is not available' do
        let(:pure_finder_available?) { false }

        it 'uses the deprecated findings finder' do
          resolve_query

          expect(mock_pure_finder).not_to have_received(:execute)
          expect(mock_deprecated_finder).to have_received(:execute)
        end
      end
    end

    context 'when given severities' do
      let(:params) { { severity: ['low'] } }
      let(:returned_findings) { [low_vulnerability_finding] }

      it 'returns vulnerability findings of the given severities' do
        is_expected.to contain_exactly(low_vulnerability_finding)
      end
    end

    context 'when given scanner' do
      let(:params) { { scanner: [high_vulnerability_finding.scanner.external_id] } }
      let(:returned_findings) { [high_vulnerability_finding] }

      it 'returns vulnerability findings of the given scanner' do
        is_expected.to contain_exactly(high_vulnerability_finding)
      end
    end

    context 'when given report types' do
      let(:params) { { report_type: %i[dast sast] } }
      let(:returned_findings) { [critical_vulnerability_finding, low_vulnerability_finding] }

      it 'returns vulnerabilities of the given report types' do
        is_expected.to contain_exactly(critical_vulnerability_finding, low_vulnerability_finding)
      end
    end

    context 'when given states' do
      let(:params) { { state: %w(detected confirmed) } }

      before do
        allow(Security::PipelineVulnerabilitiesFinder).to receive(:new).and_call_original
      end

      it 'calls the finder class with given parameters' do
        resolve_query

        expect(Security::PipelineVulnerabilitiesFinder).to have_received(:new).with(pipeline: pipeline, params: params)
      end
    end

    context 'when the finder class raises parsing error' do
      before do
        allow_next_instance_of(Security::PipelineVulnerabilitiesFinder) do |finder|
          allow(finder).to receive(:execute).and_raise(Security::PipelineVulnerabilitiesFinder::ParseError)
        end
      end

      it 'does not propagate the error to the client' do
        expect { resolve_query }.not_to raise_error
      end
    end
  end
end
