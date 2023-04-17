# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ScanPipelineService, feature_category: :security_policy_management do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let(:pipeline_scan_config) { subject[:pipeline_scan] }
    let(:on_demand_config) { subject[:on_demand] }
    let(:service) { described_class.new(project) }

    subject { service.execute(actions) }

    shared_examples 'creates scan jobs' do |on_demand_jobs: [], pipeline_scan_job_templates: []|
      it 'returns created jobs' do
        expect(::Security::SecurityOrchestrationPolicies::CiConfigurationService).to receive(:new)
                                                                                       .exactly(pipeline_scan_job_templates.size)
                                                                                       .times
                                                                                       .and_call_original
        expect(::Security::SecurityOrchestrationPolicies::OnDemandScanPipelineConfigurationService).to receive(:new)
                                                                                                         .exactly(on_demand_jobs.count)
                                                                                                         .times
                                                                                                         .and_call_original
        pipeline_scan_jobs = []

        pipeline_scan_job_templates.each_with_index do |job_template, index|
          template = ::TemplateFinder.build(:gitlab_ci_ymls, nil, name: job_template).execute
          jobs = Gitlab::Ci::Config.new(template.content).jobs.keys
          jobs.each do |job|
            pipeline_scan_jobs.append("#{job.to_s.tr('_', '-')}-#{index}".to_sym)
          end
        end

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

      it_behaves_like 'creates scan jobs', pipeline_scan_job_templates: %w[Jobs/Secret-Detection]
    end

    context 'when action contains variables' do
      let(:actions) { [{ scan: 'sast', variables: { SAST_EXCLUDED_ANALYZERS: 'semgrep' } }] }

      it 'parses variables from the action and applies them in configuration service' do
        expect_next_instance_of(::Security::SecurityOrchestrationPolicies::CiConfigurationService) do |ci_configuration_service|
          expect(ci_configuration_service).to receive(:execute).once
            .with(actions.first, { 'SAST_EXCLUDED_ANALYZERS' => 'semgrep' }, 0).and_call_original
        end

        subject
      end
    end

    context 'when action contains variables that are not allowed' do
      let(:actions) { [{ scan: 'secret_detection', variables: { SECRET_DETECTION_HISTORIC_SCAN: 'true' } }] }

      it 'ignores variables from the action and does not apply them in configuration service' do
        expect_next_instance_of(::Security::SecurityOrchestrationPolicies::CiConfigurationService) do |ci_configuration_service|
          expect(ci_configuration_service).to receive(:execute).once
            .with(actions.first, { 'SECRET_DETECTION_HISTORIC_SCAN' => 'false' }, 0).and_call_original
        end

        subject
      end

      context 'when base variables are provided when initializing the service' do
        let(:actions) { [{ scan: 'secret_detection', variables: { SECRET_DETECTION_HISTORIC_SCAN: 'false' } }] }
        let(:service) { described_class.new(project, secret_detection: { 'SECRET_DETECTION_HISTORIC_SCAN' => 'true' }) }

        it 'ignores variables from the action and does not apply them in configuration service' do
          expect_next_instance_of(::Security::SecurityOrchestrationPolicies::CiConfigurationService) do |ci_configuration_service|
            expect(ci_configuration_service).to receive(:execute).once
              .with(actions.first, { 'SECRET_DETECTION_HISTORIC_SCAN' => 'true' }, 0).and_call_original
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

      it_behaves_like 'creates scan jobs',
                      on_demand_jobs: %i[dast-on-demand-0],
                      pipeline_scan_job_templates: %w[Jobs/Secret-Detection Jobs/Container-Scanning Jobs/SAST]
    end

    context 'when there are valid and invalid actions' do
      let(:actions) do
        [
          { scan: 'secret_detection' },
          { scan: 'invalid' }
        ]
      end

      it_behaves_like 'creates scan jobs', pipeline_scan_job_templates: %w[Jobs/Secret-Detection]
    end
  end
end
