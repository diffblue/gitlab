# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ScanPipelineService, feature_category: :security_policy_management do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let(:pipeline_scan_config) { subject[:pipeline_scan] }
    let(:on_demand_config) { subject[:on_demand] }
    let_it_be(:service) { described_class.new(project) }

    subject { service.execute(actions) }

    shared_examples 'creates scan jobs' do |pipeline_scan_jobs: [], on_demand_jobs: [], template_count: nil, legacy_ci_configuration_service: false|
      it 'returns created jobs' do
        configuration_service_klass = legacy_ci_configuration_service ? ::Security::SecurityOrchestrationPolicies::LegacyCiConfigurationService : ::Security::SecurityOrchestrationPolicies::CiConfigurationService

        expect(configuration_service_klass).to receive(:new)
                                                                                       .exactly(template_count || pipeline_scan_jobs.count)
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

      context 'when scan_execution_policies_run_sast_and_ds_in_single_pipeline is enabled' do
        before do
          stub_feature_flags(scan_execution_policies_run_sast_and_ds_in_single_pipeline: true)
        end

        it 'parses variables from the action and applies them in configuration service' do
          expect_next_instance_of(::Security::SecurityOrchestrationPolicies::CiConfigurationService) do |ci_configuration_service|
            expect(ci_configuration_service).to receive(:execute).once
              .with(actions.first, { 'SAST_DISABLED' => nil, 'SAST_EXCLUDED_ANALYZERS' => 'semgrep' }, 0).and_call_original
          end

          subject
        end
      end

      context 'when scan_execution_policies_run_sast_and_ds_in_single_pipeline is disabled' do
        before do
          stub_feature_flags(scan_execution_policies_run_sast_and_ds_in_single_pipeline: false)
        end

        it 'parses variables from the action and applies them in legacy configuration service' do
          expect_next_instance_of(::Security::SecurityOrchestrationPolicies::LegacyCiConfigurationService) do |ci_configuration_service|
            expect(ci_configuration_service).to receive(:execute).once
              .with(actions.first, { 'SAST_DISABLED' => nil, 'SAST_EXCLUDED_ANALYZERS' => 'semgrep' }).and_call_original
          end

          subject
        end
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

      context 'when scan_execution_policies_run_sast_and_ds_in_single_pipeline is enabled' do
        before do
          stub_feature_flags(scan_execution_policies_run_sast_and_ds_in_single_pipeline: true)
        end

        it_behaves_like 'creates scan jobs',
                        pipeline_scan_jobs: %i[secret-detection-0 container-scanning-1
                                               sast-2 bandit-sast-2 brakeman-sast-2 eslint-sast-2 flawfinder-sast-2
                                               kubesec-sast-2 gosec-sast-2 mobsf-android-sast-2 mobsf-ios-sast-2
                                               nodejs-scan-sast-2 phpcs-security-audit-sast-2 pmd-apex-sast-2
                                               security-code-scan-sast-2 semgrep-sast-2 sobelow-sast-2 spotbugs-sast-2],
                        on_demand_jobs: %i[dast-on-demand-0],
                        template_count: 3
      end

      context 'when scan_execution_policies_run_sast_and_ds_in_single_pipeline is disabled' do
        before do
          stub_feature_flags(scan_execution_policies_run_sast_and_ds_in_single_pipeline: false)
        end

        it_behaves_like 'creates scan jobs',
                        pipeline_scan_jobs: %i[secret-detection-0 container-scanning-1 sast-2],
                        on_demand_jobs: %i[dast-on-demand-0],
                        legacy_ci_configuration_service: true
      end
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
