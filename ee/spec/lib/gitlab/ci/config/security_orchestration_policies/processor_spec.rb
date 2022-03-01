# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::SecurityOrchestrationPolicies::Processor do
  include Ci::TemplateHelpers

  subject { described_class.new(config, project, ref, source).perform }

  let_it_be(:config) { { image: 'ruby:3.0.1' } }

  let(:ref) { 'refs/heads/master' }
  let(:source) { 'pipeline' }

  let_it_be_with_refind(:project) { create(:project, :repository) }

  let_it_be(:policies_repository) { create(:project, :repository) }
  let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, project: project, security_policy_management_project: policies_repository) }
  let_it_be(:policy) do
    build(:scan_execution_policy, actions: [
    { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' },
    { scan: 'secret_detection' }
  ])
  end

  let_it_be(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [policy]) }

  before do
    allow_next_instance_of(Repository) do |repository|
      allow(repository).to receive(:blob_data_at).and_return(policy_yaml)
    end
  end

  shared_examples 'with pipeline source applicable for CI' do
    let_it_be(:source) { 'ondemand_dast_scan' }

    it 'does not modify the config' do
      expect(subject).to eq(config)
    end
  end

  shared_examples 'with different scan type' do
    it 'extends config with additional jobs' do
      expect(subject).to include(expected_configuration)
    end
  end

  shared_examples 'when policy is invalid' do
    let_it_be(:policy_yaml) do
      build(:orchestration_policy_yaml, scan_execution_policy:
      [build(:scan_execution_policy, rules: [{ type: 'pipeline', branches: 'production' }])])
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

    context 'when policy is not applicable on branch from the pipeline' do
      let(:ref) { 'refs/head/another-branch' }

      it 'does not modify the config' do
        expect(subject).to eq(config)
      end
    end

    context 'when ref is a tag' do
      let(:ref) { 'refs/tags/v1.1.0' }

      it 'does not modify the config' do
        expect(subject).to eq(config)
      end
    end

    context 'when policy is applicable on branch from the pipeline' do
      let(:ref) { 'refs/heads/master' }

      context 'when DAST profiles are not found' do
        it 'does not modify the config' do
          expect(subject[:'dast-on-demand-0']).to eq({ allow_failure: true, script: 'echo "Error during On-Demand Scan execution: Dast site profile was not provided" && false' })
        end
      end

      it_behaves_like 'with pipeline source applicable for CI'
      it_behaves_like 'when policy is invalid'

      context 'when DAST profiles are found' do
        let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, name: 'Scanner Profile') }
        let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project, name: 'Site Profile') }

        it_behaves_like 'with different scan type' do
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
        end

        it_behaves_like 'with pipeline source applicable for CI'
        it_behaves_like 'when policy is invalid'
      end

      context 'when scan type is secret_detection' do
        it_behaves_like 'with different scan type' do
          let(:expected_configuration) do
            {
              'secret-detection-0': hash_including(
                rules: [{ if: '$SECRET_DETECTION_DISABLED', when: 'never' }, { if: '$CI_COMMIT_BRANCH' }],
                stage: 'test',
                image: '$SECURE_ANALYZERS_PREFIX/secrets:$SECRETS_ANALYZER_VERSION',
                services: [],
                allow_failure: true,
                artifacts: {
                  reports: {
                    secret_detection: 'gl-secret-detection-report.json'
                  }
                },
                variables: {
                  GIT_DEPTH: '50',
                  SECURE_ANALYZERS_PREFIX: secure_analyzers_prefix,
                  SECRETS_ANALYZER_VERSION: '3',
                  SECRET_DETECTION_EXCLUDED_PATHS: '',
                  SECRET_DETECTION_HISTORIC_SCAN: 'false'
                })
            }
          end
        end
      end
    end
  end
end
