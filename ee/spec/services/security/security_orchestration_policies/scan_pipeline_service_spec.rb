# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ScanPipelineService do
  describe '#execute' do
    let_it_be(:service) { described_class.new }

    subject { service.execute(actions) }

    shared_examples 'creates scan jobs' do |times, job_names|
      it 'returns created jobs' do
        expect(::Security::SecurityOrchestrationPolicies::CiConfigurationService).to receive(:new).exactly(times).times.and_call_original

        expect(subject.keys).to eq(job_names)
      end
    end

    context 'when there is an invalid action' do
      let(:actions) { [{ scan: 'invalid' }] }

      it 'does not create scan job' do
        expect(::Security::SecurityOrchestrationPolicies::CiConfigurationService).not_to receive(:new)

        expect(subject.keys).to eq([])
      end
    end

    context 'when there is only one action' do
      let(:actions) { [{ scan: 'secret_detection' }] }

      it_behaves_like 'creates scan jobs', 1, [:'secret-detection-0']
    end

    context 'when action contains variables' do
      let(:actions) { [{ scan: 'sast', variables: { SAST_EXCLUDED_ANALYZERS: 'semgrep' } }] }

      it 'parses variables from the action and applies them in configuration service' do
        expect_next_instance_of(::Security::SecurityOrchestrationPolicies::CiConfigurationService) do |ci_configuration_service|
          expect(ci_configuration_service).to receive(:execute).once.with(actions.first, 'SAST_DISABLED' => nil, 'SAST_EXCLUDED_ANALYZERS' => 'semgrep').and_call_original
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

      it_behaves_like 'creates scan jobs', 5, [:'secret-detection-0', :'dast-1', :'cluster-image-scanning-2', :'container-scanning-3', :'sast-4']
    end

    context 'when there are valid and invalid actions' do
      let(:actions) do
        [
          { scan: 'secret_detection' },
          { scan: 'invalid' }
        ]
      end

      it_behaves_like 'creates scan jobs', 1, [:'secret-detection-0']
    end
  end
end
