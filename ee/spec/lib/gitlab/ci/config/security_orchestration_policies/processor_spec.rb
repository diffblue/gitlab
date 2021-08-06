# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::SecurityOrchestrationPolicies::Processor do
  include Ci::TemplateHelpers

  subject { described_class.new(config, project, ref, source).perform }

  let_it_be(:config) { { image: 'ruby:3.0.1' } }

  let(:ref) { 'master' }
  let(:source) { 'pipeline' }

  let_it_be_with_refind(:project) { create(:project, :repository) }

  let_it_be(:policies_repository) { create(:project, :repository) }
  let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, project: project, security_policy_management_project: policies_repository) }

  let_it_be(:policy_yml) do
    <<-EOS
    scan_execution_policy:
      -  name: Run DAST in every pipeline
         description: This policy enforces to run DAST for every pipeline within the project
         enabled: true
         rules:
         - type: pipeline
           branches:
           - "production"
         actions:
         - scan: dast
           site_profile: Site Profile
           scanner_profile: Scanner Profile
    EOS
  end

  before do
    allow_next_instance_of(Repository) do |repository|
      allow(repository).to receive(:blob_data_at).and_return(policy_yml)
    end
  end

  shared_examples 'with pipeline source applicable for CI' do
    let_it_be(:source) { 'ondemand_dast_scan' }

    it 'does not modify the config' do
      expect(subject).to eq(config)
    end
  end

  shared_examples 'when policy is invalid' do
    let_it_be(:policy_yml) do
      <<-EOS
      scan_execution_policy:
        -  name: Run DAST in every pipeline
           description: This policy enforces to run DAST for every pipeline within the project
           enabled: true
           rules:
           - type: pipeline
             branches: "production"
           actions:
           - scan: dast
             site_profile: Site Profile
             scanner_profile: Scanner Profile
      EOS
    end

    it 'does not modify the config', :aggregate_failures do
      expect(config).not_to receive(:deep_merge)
      expect(subject).to eq(config)
    end
  end

  context 'when feature is not licensed' do
    it 'does not modify the config' do
      expect(subject).to eq(config)
    end
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(security_orchestration_policies: true)
    end

    context 'when feature is not enabled' do
      before do
        stub_feature_flags(security_orchestration_policies_configuration: false)
      end

      it 'does not modify the config' do
        expect(subject).to eq(config)
      end
    end

    context 'when feature is enabled' do
      before do
        stub_feature_flags(security_orchestration_policies_configuration: true)
      end

      context 'when policy is not applicable on branch from the pipeline' do
        it 'does not modify the config' do
          expect(subject).to eq(config)
        end
      end

      context 'when policy is not applicable on branch from the pipeline' do
        let_it_be(:ref) { 'production' }

        context 'when DAST profiles are not found' do
          it 'does not modify the config' do
            expect(subject).to eq(
              image: 'ruby:3.0.1',
              'dast-on-demand-0': { allow_failure: true, script: 'echo "Error during On-Demand Scan execution: Dast site profile was not provided" && false' }
            )
          end
        end

        it_behaves_like 'with pipeline source applicable for CI'
        it_behaves_like 'when policy is invalid'

        context 'when DAST profiles are found' do
          let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, name: 'Scanner Profile') }
          let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project, name: 'Site Profile') }

          let(:expected_configuration) do
            {
              image: 'ruby:3.0.1',
              'dast-on-demand-0': {
                stage: 'dast',
                image: {
                  name: '$SECURE_ANALYZERS_PREFIX/dast:$DAST_VERSION'
                },
                variables: {
                  DAST_VERSION: 2,
                  SECURE_ANALYZERS_PREFIX: secure_analyzers_prefix,
                  GIT_STRATEGY: 'none'
                },
                allow_failure: true,
                script: ['/analyze'],
                artifacts: {
                  reports: {
                    dast: 'gl-dast-report.json'
                  }
                },
                dast_configuration: {
                  site_profile: dast_site_profile.name,
                  scanner_profile: dast_scanner_profile.name
                }
              }
            }
          end

          it 'extends config with additional jobs' do
            expect(subject).to include(expected_configuration)
          end

          it_behaves_like 'with pipeline source applicable for CI'
          it_behaves_like 'when policy is invalid'
        end
      end
    end
  end
end
