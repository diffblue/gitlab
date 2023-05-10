# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::SecurityOrchestrationPolicies::Processor, feature_category: :security_policy_management do
  subject { described_class.new(config, project, ref, source).perform }

  let_it_be(:config) { { image: 'image:1.0.0' } }

  let(:ref) { 'refs/heads/master' }
  let(:source) { 'pipeline' }
  let(:scan_policy_stage) { 'test' }

  let_it_be(:namespace) { create(:group) }
  let_it_be(:namespace_policies_repository) { create(:project, :repository) }
  let_it_be(:namespace_security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace, namespace: namespace, security_policy_management_project: namespace_policies_repository) }
  let_it_be(:namespace_policy) do
    build(:scan_execution_policy, actions: [
            { scan: 'sast' },
            { scan: 'secret_detection' }
          ])
  end

  let_it_be_with_refind(:project) { create(:project, :repository, group: namespace) }

  let_it_be(:policies_repository) { create(:project, :repository, group: namespace) }
  let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, project: project, security_policy_management_project: policies_repository) }
  let_it_be(:policy) do
    build(:scan_execution_policy, actions: [
            { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' },
            { scan: 'secret_detection' }
          ])
  end

  let_it_be(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [policy]) }
  let_it_be(:namespace_policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [namespace_policy]) }

  before do
    allow_next_instance_of(Repository, anything, anything, anything) do |repository|
      allow(repository).to receive(:blob_data_at).and_return(policy_yaml)
    end

    allow_next_instance_of(Repository, anything, namespace_policies_repository, anything) do |repository|
      allow(repository).to receive(:blob_data_at).and_return(namespace_policy_yaml)
    end
  end

  shared_examples 'with pipeline source applicable for CI' do
    let_it_be(:source) { 'ondemand_dast_scan' }

    it 'does not modify the config' do
      expect(subject).to eq(config)
    end
  end

  shared_examples 'with different scan type' do
    %w[api pipeline merge_request_event schedule].each do |ci_source|
      context "when #{ci_source} pipeline is created and affects CI status of the ref" do
        let(:source) { ci_source }

        context 'when config already have jobs with names provided by policies' do
          let(:config) do
            {
              stages: %w[build test release],
              image: 'image:1.0.0',
              'dast-on-demand-0': {
                rules: [{ if: '$CI_COMMIT_BRANCH == "develop"' }],
                needs: [{ job: 'build-job', artifacts: true }]
              },
              'sast-0': {
                rules: [{ if: '$CI_COMMIT_BRANCH == "develop"' }],
                needs: [{ job: 'build-job', artifacts: true }]
              },
              'secret-detection-1': {
                rules: [{ if: '$CI_COMMIT_BRANCH == "develop"' }],
                needs: [{ job: 'build-job', artifacts: true }]
              }
            }
          end

          it 'extends config with additional jobs without overriden values', :aggregate_failures do
            expect(subject.keys).to include(expected_jobs)
            expect(subject.values).to include(expected_configuration)
            expect(subject[extended_job]).not_to include(
              rules: [{ if: '$CI_COMMIT_BRANCH == "develop"' }],
              needs: [{ job: 'build-job', artifacts: true }]
            )
          end
        end

        context 'when test stage is available' do
          let(:config) { { stages: %w[build test release], image: 'image:1.0.0' } }

          it 'does not include scan-policies stage' do
            expect(subject[:stages]).to eq(%w[build test release dast])
          end

          it 'extends config with additional jobs' do
            expect(subject.keys).to include(expected_jobs)
            expect(subject.values).to include(expected_configuration)
          end
        end

        context 'when test stage is not available' do
          let(:scan_policy_stage) { 'scan-policies' }

          context 'when build stage is available' do
            let(:config) { { stages: %w[build not-test release], image: 'image:1.0.0' } }

            it 'includes scan-policies stage after build stage' do
              expect(subject[:stages]).to eq(%w[build scan-policies not-test release dast])
            end

            it 'extends config with additional jobs' do
              expect(subject.keys).to include(expected_jobs)
              expect(subject.values).to include(expected_configuration)
            end
          end

          context 'when build stage is not available' do
            let(:config) { { stages: %w[not-test release], image: 'image:1.0.0' } }

            it 'includes scan-policies stage as a first stage' do
              expect(subject[:stages]).to eq(%w[scan-policies not-test release dast])
            end

            it 'extends config with additional jobs' do
              expect(subject.keys).to include(expected_jobs)
              expect(subject.values).to include(expected_configuration)
            end
          end
        end
      end
    end
  end

  shared_examples 'when policy is invalid' do
    let_it_be(:policy_yaml) do
      build(:orchestration_policy_yaml, scan_execution_policy:
      [build(:scan_execution_policy, rules: [{ type: 'pipeline', branches: 'production' }])])
    end

    let_it_be(:namespace_policy_yaml) do
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
          let(:extended_job) { :'dast-on-demand-0' }
          let(:expected_jobs) { starting_with('dast-on-demand-') }
          let(:expected_configuration) do
            {
              stage: 'dast',
              image: {
                name: '$SECURE_ANALYZERS_PREFIX/dast:$DAST_VERSION'
              },
              variables: {
                DAST_VERSION: 3,
                SECURE_ANALYZERS_PREFIX: '$CI_TEMPLATE_REGISTRY_HOST/security-products',
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
          end
        end

        it_behaves_like 'with pipeline source applicable for CI'
        it_behaves_like 'when policy is invalid'
      end

      context 'when scan type is secret_detection' do
        it_behaves_like 'with different scan type' do
          let(:extended_job) { :'secret-detection-1' }
          let(:expected_jobs) { starting_with('secret-detection-') }
          let(:expected_configuration) do
            hash_including(
              rules: [{ if: '$CI_COMMIT_BRANCH' }],
              script: ["/analyzer run"],
              stage: scan_policy_stage,
              image: '$SECURE_ANALYZERS_PREFIX/secrets:$SECRETS_ANALYZER_VERSION$SECRET_DETECTION_IMAGE_SUFFIX',
              services: [],
              allow_failure: true,
              artifacts: {
                reports: {
                  secret_detection: 'gl-secret-detection-report.json'
                }
              },
              variables: {
                GIT_DEPTH: '50',
                SECURE_ANALYZERS_PREFIX: '$CI_TEMPLATE_REGISTRY_HOST/security-products',
                SECRETS_ANALYZER_VERSION: '5',
                SECRET_DETECTION_IMAGE_SUFFIX: '',
                SECRET_DETECTION_EXCLUDED_PATHS: '',
                SECRET_DETECTION_HISTORIC_SCAN: 'false'
              })
          end
        end
      end

      context 'when scan type is sast is configured for namespace policy project' do
        it_behaves_like 'with different scan type' do
          let(:extended_job) { :'sast-0' }
          let(:expected_jobs) { ending_with('-sast-0') }
          let(:expected_configuration) do
            hash_including(
              artifacts: { reports: { sast: 'gl-sast-report.json' } },
              script: ['/analyzer run'],
              image: { name: '$SAST_ANALYZER_IMAGE' },
              rules: [
                { if: '$SAST_EXCLUDED_ANALYZERS =~ /brakeman/', when: 'never' },
                { if: '$CI_COMMIT_BRANCH', exists: ['**/*.rb', '**/Gemfile'] }
              ]
            )
          end
        end
      end
    end
  end
end
