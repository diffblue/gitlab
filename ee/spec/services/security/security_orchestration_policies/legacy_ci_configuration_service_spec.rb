# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::LegacyCiConfigurationService,
feature_category: :security_policy_management do
  describe '#execute' do
    let_it_be(:service) { described_class.new }
    let_it_be(:ci_variables) do
      { 'SECRET_DETECTION_HISTORIC_SCAN' => 'false', 'SECRET_DETECTION_DISABLED' => nil }
    end

    subject { service.execute(action, ci_variables) }

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

        it_behaves_like 'with template name for scan type'

        it 'returns prepared CI configuration with Secret Detection scans' do
          expected_configuration = {
            rules: [{ if: '$SECRET_DETECTION_DISABLED', when: 'never' }, { if: '$CI_COMMIT_BRANCH' }],
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
              SECRETS_ANALYZER_VERSION: '4',
              SECRET_DETECTION_IMAGE_SUFFIX: '',
              SECRET_DETECTION_EXCLUDED_PATHS: '',
              SECRET_DETECTION_HISTORIC_SCAN: 'false'
            }
          }

          expect(subject.deep_symbolize_keys).to eq(expected_configuration)
        end
      end

      context 'when scan type is container_scanning' do
        let_it_be(:action) { { scan: 'container_scanning', tags: ['runner-tag'] } }
        let_it_be(:template_name) { 'Jobs/Container-Scanning' }
        let_it_be(:ci_variables) { {} }

        it_behaves_like 'with template name for scan type'

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
              paths: ['gl-container-scanning-report.json', 'gl-dependency-scanning-report.json']
            },
            dependencies: [],
            script: ['gtcs scan'],
            variables: {
              CS_ANALYZER_IMAGE: "$CI_TEMPLATE_REGISTRY_HOST/security-products/container-scanning:5",
              GIT_STRATEGY: 'none'
            },
            rules: [
              { if: "$CONTAINER_SCANNING_DISABLED", when: "never" },
              {
                if: '$CI_COMMIT_BRANCH && '\
                    '$CI_GITLAB_FIPS_MODE == "true" && $CS_ANALYZER_IMAGE !~ /-(fips|ubi)\z/',
                variables: { CS_IMAGE_SUFFIX: '-fips' }
              },
              { if: '$CI_COMMIT_BRANCH' }
            ]
          }

          expect(subject.deep_symbolize_keys).to eq(expected_configuration)
        end
      end

      context 'when scan type is sast' do
        let_it_be(:action) { { scan: 'sast', tags: ['runner-tag'] } }
        let_it_be(:ci_variables) { { 'SAST_EXCLUDED_ANALYZERS' => 'semgrep', 'SAST_DISABLED' => nil } }

        it 'returns prepared CI configuration for SAST' do
          expected_configuration = {
            inherit: { variables: false },
            variables: { 'SAST_EXCLUDED_ANALYZERS' => 'semgrep' },
            trigger: { include: [{ template: 'Security/SAST.gitlab-ci.yml' }] }
          }

          expect(subject).to eq(expected_configuration)
        end

        context 'when variables are empty' do
          let_it_be(:ci_variables) { {} }

          it 'returns prepared CI configuration for SAST' do
            expected_configuration = {
              inherit: { variables: false },
              trigger: { include: [{ template: 'Security/SAST.gitlab-ci.yml' }] }
            }

            expect(subject).to eq(expected_configuration)
          end
        end
      end

      context 'when scan type is dependency_scanning' do
        let_it_be(:action) { { scan: 'dependency_scanning', tags: ['runner-tag'] } }
        let_it_be(:ci_variables) do
          { 'DS_EXCLUDED_ANALYZERS' => 'gemnasium-python', 'DEPENDENCY_SCANNING_DISABLED' => nil }
        end

        it 'returns prepared CI configuration for Dependency Scanning' do
          expected_configuration = {
            inherit: { variables: false },
            variables: { 'DS_EXCLUDED_ANALYZERS' => 'gemnasium-python' },
            trigger: { include: [{ template: 'Jobs/Dependency-Scanning.gitlab-ci.yml' }] }
          }

          expect(subject).to eq(expected_configuration)
        end

        context 'when variables are empty' do
          let_it_be(:ci_variables) { {} }

          it 'returns prepared CI configuration for Dependency Scanning' do
            expected_configuration = {
              inherit: { variables: false },
              trigger: { include: [{ template: 'Jobs/Dependency-Scanning.gitlab-ci.yml' }] }
            }

            expect(subject).to eq(expected_configuration)
          end
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

        expect(subject).to eq(expected_configuration)
      end
    end
  end
end
