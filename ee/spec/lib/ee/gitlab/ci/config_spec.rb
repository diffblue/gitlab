# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config do
  let_it_be(:ci_yml) do
    <<-EOS
    sample_job:
      script:
      - echo 'test'
    EOS
  end

  describe 'with required instance template' do
    let(:template_name) { 'test_template' }
    let(:template_repository) { create(:project, :custom_repo, files: { "gitlab-ci/#{template_name}.yml" => template_yml }) }

    let(:template_yml) do
      <<-EOS
      sample_job:
        script:
          - echo 'not test'
      EOS
    end

    subject(:config) { described_class.new(ci_yml) }

    before do
      stub_application_setting(file_template_project: template_repository, required_instance_ci_template: template_name)
      stub_licensed_features(custom_file_templates: true, required_ci_templates: true)
    end

    it 'processes the required includes' do
      expect(config.to_hash[:sample_job][:script]).to eq(["echo 'not test'"])
    end
  end

  describe 'with security orchestration policy' do
    let(:source) { 'push' }

    let(:ref) { 'master' }
    let_it_be_with_refind(:project) { create(:project, :repository) }

    let_it_be(:policies_repository) { create(:project, :repository) }
    let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, project: project, security_policy_management_project: policies_repository) }
    let_it_be(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [build(:scan_execution_policy)]) }

    let(:pipeline) { build(:ci_pipeline, project: project, ref: ref) }

    subject(:config) { described_class.new(ci_yml, pipeline: pipeline, project: project, source: source) }

    before do
      allow_next_instance_of(Repository) do |repository|
        # allow(repository).to receive(:ls_files).and_return(['.gitlab/security-policies/enforce-dast.yml'])
        allow(repository).to receive(:blob_data_at).and_return(policy_yaml)
      end
    end

    context 'when feature is not licensed' do
      it 'does not modify the config' do
        expect(config.to_hash).to eq(sample_job: { script: ["echo 'test'"] })
      end
    end

    context 'when feature is licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when policy is not applicable on branch from the pipeline' do
        let(:ref) { 'another-branch' }

        it 'does not modify the config' do
          expect(config.to_hash).to eq(sample_job: { script: ["echo 'test'"] })
        end
      end

      context 'when policy is applicable on branch from the pipeline' do
        let(:ref) { 'master' }

        context 'when DAST profiles are not found' do
          it 'adds a job with error message' do
            expect(config.to_hash).to eq(
              stages: [".pre", "build", "test", "deploy", ".post", "dast"],
              sample_job: { script: ["echo 'test'"] },
              'dast-on-demand-0': { allow_failure: true, script: 'echo "Error during On-Demand Scan execution: Dast site profile was not provided" && false' }
            )
          end
        end

        context 'when DAST profiles are found' do
          let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, name: 'Scanner Profile') }
          let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project, name: 'Site Profile') }

          let(:expected_configuration) do
            {
              sample_job: {
                script: ["echo 'test'"]
              },
              'dast-on-demand-0': {
                stage: 'dast',
                image: { name: '$SECURE_ANALYZERS_PREFIX/dast:$DAST_VERSION' },
                variables: {
                  DAST_VERSION: 4,
                  SECURE_ANALYZERS_PREFIX: '$CI_TEMPLATE_REGISTRY_HOST/security-products',
                  GIT_STRATEGY: 'none'
                },
                allow_failure: true,
                script: ['/analyze'],
                artifacts: { reports: { dast: 'gl-dast-report.json' } },
                dast_configuration: {
                  site_profile: dast_site_profile.name,
                  scanner_profile: dast_scanner_profile.name
                }
              }
            }
          end

          it 'extends config with additional jobs' do
            expect(config.to_hash).to include(expected_configuration)
          end

          context 'when source is ondemand_dast_scan' do
            let(:source) { 'ondemand_dast_scan' }

            it 'does not modify the config' do
              expect(config.to_hash).to eq(sample_job: { script: ["echo 'test'"] })
            end
          end
        end
      end
    end
  end
end
