# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ScanPipelineService do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let(:pipeline_scan_config) { subject[:pipeline_scan] }
    let(:on_demand_config) { subject[:on_demand] }
    let_it_be(:service) { described_class.new(project) }

    subject { service.execute(actions) }

    shared_examples 'creates scan jobs' do |pipeline_scan_jobs: [], on_demand_jobs: []|
      it 'returns created jobs' do
        expect(::Security::SecurityOrchestrationPolicies::CiConfigurationService).to receive(:new)
                                                                                       .exactly(pipeline_scan_jobs.count)
                                                                                       .times
                                                                                       .and_call_original
        expect(::Security::SecurityOrchestrationPolicies::OnDemandScanPipelineConfigurationService).to receive(:new)
                                                                                                         .exactly(on_demand_jobs.count)
                                                                                                         .times
                                                                                                         .and_call_original

        expect(pipeline_scan_config.keys).to eq(pipeline_scan_jobs)
        expect(on_demand_config.keys).to eq(on_demand_jobs)
      end
    end

    context 'when there is an invalid action' do
      let(:actions) { [{ scan: 'invalid' }] }

      it 'does not create scan job' do
        expect(::Security::SecurityOrchestrationPolicies::CiConfigurationService).not_to receive(:new)
        expect(::Security::SecurityOrchestrationPolicies::OnDemandScanPipelineConfigurationService).not_to receive(:new)

        [pipeline_scan_config, on_demand_config].each do |config|
          expect(config.keys).to eq([])
        end
      end
    end

    context 'when there is only one action' do
      let(:actions) { [{ scan: 'secret_detection' }] }

      it_behaves_like 'creates scan jobs', pipeline_scan_jobs: %i[secret-detection-0]
    end

    context 'when action contains variables' do
      let(:actions) { [{ scan: 'sast', variables: { SAST_EXCLUDED_ANALYZERS: 'semgrep' } }] }

      it 'parses variables from the action and applies them in configuration service' do
        expect_next_instance_of(::Security::SecurityOrchestrationPolicies::CiConfigurationService) do |ci_configuration_service|
          expect(ci_configuration_service).to receive(:execute).once
            .with(actions.first, { 'SAST_DISABLED' => nil, 'SAST_EXCLUDED_ANALYZERS' => 'semgrep' }).and_call_original
        end

        subject
      end
    end

    context 'when there are multiple actions' do
      let(:actions) do
        [
          { scan: 'secret_detection' },
          { scan: 'dast', scanner_profile: 'Scanner Profile', site_profile: 'Site Profile' },
          { scan: 'cluster_image_scanning' },
          { scan: 'container_scanning' },
          { scan: 'sast' }
        ]
      end

      it_behaves_like 'creates scan jobs',
                      pipeline_scan_jobs: %i[secret-detection-0 container-scanning-1 sast-2],
                      on_demand_jobs: %i[dast-on-demand-0]
    end

    context 'when there are valid and invalid actions' do
      let(:actions) do
        [
          { scan: 'secret_detection' },
          { scan: 'invalid' }
        ]
      end

      it_behaves_like 'creates scan jobs', pipeline_scan_jobs: %i[secret-detection-0]
    end
  end
end
