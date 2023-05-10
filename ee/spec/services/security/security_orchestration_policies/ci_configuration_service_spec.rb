# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::CiConfigurationService,
  feature_category: :security_policy_management do
  describe '#execute' do
    let_it_be(:service) { described_class.new }
    let_it_be(:ci_variables) do
      { 'SECRET_DETECTION_HISTORIC_SCAN' => 'false', 'SECRET_DETECTION_DISABLED' => nil }
    end

    subject { service.execute(action, ci_variables, 0) }

    shared_examples 'with template name for scan type' do
      it 'fetches template content using ::TemplateFinder' do
        expect(::TemplateFinder).to receive(:build).with(:gitlab_ci_ymls, nil, name: template_name).and_call_original

        subject
      end
    end

    context 'when action is valid' do
      context 'when scan type is secret_detection' do
        let_it_be(:action) { { scan: 'secret_detection', tags: ['runner-tag'] } }
        let_it_be(:template_name) { 'Jobs/Secret-Detection' }
        let_it_be(:ci_variables) do
          { 'SECRET_DETECTION_HISTORIC_SCAN' => 'false', 'SECRET_DETECTION_IMAGE_SUFFIX' => 'suffix' }
        end

        it_behaves_like 'with template name for scan type'

        it 'merges template variables with ci variables and returns them as string' do
          expect(subject[:'secret-detection-0']).to include(
            variables: hash_including(
              'SECRET_DETECTION_HISTORIC_SCAN' => 'false',
              'SECRET_DETECTION_IMAGE_SUFFIX' => 'suffix'
            )
          )
        end

        it 'returns prepared CI configuration with Secret Detection scans' do
          expected_configuration = {
            rules: [{ if: '$CI_COMMIT_BRANCH' }],
            script: ["/analyzer run"],
            tags: ['runner-tag'],
            stage: 'test',
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
              SECRET_DETECTION_IMAGE_SUFFIX: 'suffix',
              SECRET_DETECTION_EXCLUDED_PATHS: '',
              SECRET_DETECTION_HISTORIC_SCAN: 'false'
            }
          }

          expect(subject.deep_symbolize_keys).to eq('secret-detection-0': expected_configuration)
        end
      end

      context 'when scan type is container_scanning' do
        let_it_be(:action) { { scan: 'container_scanning', tags: ['runner-tag'] } }
        let_it_be(:template_name) { 'Jobs/Container-Scanning' }
        let_it_be(:ci_variables) { { 'GIT_STRATEGY' => 'fetch', 'VARIABLE_1' => 10 } }

        it_behaves_like 'with template name for scan type'

        it 'merges template variables with ci variables and returns them as string' do
          expect(subject[:'container-scanning-0']).to include(
            variables: hash_including(
              'GIT_STRATEGY' => 'fetch',
              'VARIABLE_1' => 10
            )
          )
        end

        it 'returns prepared CI configuration for Container Scanning' do
          expected_configuration = {
            image: '$CS_ANALYZER_IMAGE$CS_IMAGE_SUFFIX',
            stage: 'test',
            tags: ['runner-tag'],
            allow_failure: true,
            artifacts: {
              reports: {
                container_scanning: 'gl-container-scanning-report.json',
                dependency_scanning: 'gl-dependency-scanning-report.json'
              },
              paths: [
                'gl-container-scanning-report.json', 'gl-dependency-scanning-report.json', "**/gl-sbom-*.cdx.json"
              ]
            },
            dependencies: [],
            script: ['gtcs scan'],
            variables: {
              CS_ANALYZER_IMAGE: "$CI_TEMPLATE_REGISTRY_HOST/security-products/container-scanning:5",
              GIT_STRATEGY: 'fetch',
              VARIABLE_1: 10,
              CS_SCHEMA_MODEL: 15
            },
            rules: [
              {
                if: '$CI_COMMIT_BRANCH && '\
                    '$CI_GITLAB_FIPS_MODE == "true" && $CS_ANALYZER_IMAGE !~ /-(fips|ubi)\z/',
                variables: { CS_IMAGE_SUFFIX: '-fips' }
              },
              { if: '$CI_COMMIT_BRANCH' }
            ]
          }

          expect(subject.deep_symbolize_keys).to eq('container-scanning-0': expected_configuration)
        end
      end

      context 'when scan type is sast', :aggregate_failures do
        let_it_be(:action) { { scan: 'sast', tags: ['runner-tag'] } }
        let_it_be(:ci_variables) { { 'SAST_EXCLUDED_ANALYZERS' => 'semgrep', 'SAST_DISABLED' => nil } }

        it 'returns prepared CI configuration for SAST' do
          expected_jobs = [
            :"sast-0",
            :"bandit-sast-0",
            :"brakeman-sast-0",
            :"eslint-sast-0",
            :"flawfinder-sast-0",
            :"kubesec-sast-0",
            :"gosec-sast-0",
            :"mobsf-android-sast-0",
            :"mobsf-ios-sast-0",
            :"nodejs-scan-sast-0",
            :"phpcs-security-audit-sast-0",
            :"pmd-apex-sast-0",
            :"security-code-scan-sast-0",
            :"semgrep-sast-0",
            :"sobelow-sast-0",
            :"spotbugs-sast-0"
          ]

          expected_variables = {
            'SEARCH_MAX_DEPTH' => 4,
            'SECURE_ANALYZERS_PREFIX' => '$CI_TEMPLATE_REGISTRY_HOST/security-products',
            'SAST_IMAGE_SUFFIX' => '',
            'SAST_EXCLUDED_ANALYZERS' => 'semgrep',
            'SAST_EXCLUDED_PATHS' => 'spec, test, tests, tmp',
            'SCAN_KUBERNETES_MANIFESTS' => 'false'
          }

          expect(subject[:variables]).to be_nil
          expect(subject[:'sast-0'][:variables].stringify_keys).to include(expected_variables)
          expect(subject.keys).to match_array(expected_jobs)
        end
      end

      context 'when scan type is dependency_scanning', :aggregate_failures do
        let_it_be(:action) { { scan: 'dependency_scanning', tags: ['runner-tag'] } }
        let_it_be(:ci_variables) do
          { 'DS_EXCLUDED_ANALYZERS' => 'gemnasium-python' }
        end

        it 'returns prepared CI configuration for Dependency Scanning' do
          expected_jobs = [
            :"dependency-scanning-0",
            :"gemnasium-dependency-scanning-0",
            :"gemnasium-maven-dependency-scanning-0",
            :"gemnasium-python-dependency-scanning-0",
            :"bundler-audit-dependency-scanning-0",
            :"retire-js-dependency-scanning-0"
          ]

          expected_variables = {
            'SECURE_ANALYZERS_PREFIX' => "$CI_TEMPLATE_REGISTRY_HOST/security-products",
            'DS_EXCLUDED_PATHS' => "spec, test, tests, tmp",
            'DS_MAJOR_VERSION' => 4,
            'DS_EXCLUDED_ANALYZERS' => "gemnasium-python"
          }

          expect(subject[:variables]).to be_nil
          expect(subject[:'dependency-scanning-0'][:variables]).to include(expected_variables)
          expect(subject.keys).to match_array(expected_jobs)
        end
      end

      context 'when scan type is sast_iac', :aggregate_failures do
        let_it_be(:action) { { scan: 'sast_iac', tags: ['runner-tag'] } }

        it 'returns prepared CI configuration for SAST IaC' do
          expected_jobs = [
            :"iac-sast-0",
            :"kics-iac-sast-0"
          ]

          expect(subject[:variables]).to be_nil
          expect(subject.keys).to match_array(expected_jobs)
        end
      end
    end

    context 'when action is invalid' do
      let_it_be(:action) { { scan: 'invalid_type' } }

      it 'returns prepared CI configuration with error script' do
        expected_configuration = {
          'allow_failure' => true,
          'script' => "echo \"Error during Scan execution: Invalid Scan type\" && false"
        }

        expect(subject).to eq('invalid-type-0': expected_configuration)
      end
    end
  end
end
