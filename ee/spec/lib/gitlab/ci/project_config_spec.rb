# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::ProjectConfig, feature_category: :continuous_integration do
  let(:project) { create(:project, ci_config_path: nil) }
  let(:sha) { '123456' }
  let(:content) { nil }
  let(:source) { :push }
  let(:bridge) { nil }
  let(:security_policies) { {} }

  let(:content_result) do
    <<~CICONFIG
    ---
    include:
    - project: compliance/hippa
      file: ".compliance-gitlab-ci.yml"
    CICONFIG
  end

  subject(:config) do
    described_class.new(project: project, sha: sha,
                        custom_content: content, pipeline_source: source, pipeline_source_bridge: bridge)
  end

  shared_examples 'does not include compliance pipeline configuration content' do
    it do
      expect(config.source).not_to eq(:compliance_source)
      expect(config.content).not_to eq(content_result)
    end
  end

  context 'when project has compliance label defined' do
    let(:compliance_group) { create(:group, :private, name: "compliance") }
    let(:compliance_project) { create(:project, namespace: compliance_group, name: "hippa") }

    context 'when feature is available' do
      before do
        stub_licensed_features(evaluate_group_level_compliance_pipeline: true)
      end

      context 'when compliance pipeline configuration is defined' do
        let(:framework) do
          create(:compliance_framework,
                 namespace: compliance_group,
                 pipeline_configuration_full_path: ".compliance-gitlab-ci.yml@compliance/hippa")
        end

        let!(:framework_project_setting) do
          create(:compliance_framework_project_setting, project: project, compliance_management_framework: framework)
        end

        it 'includes compliance pipeline configuration content' do
          expect(config.source).to eq(:compliance_source)
          expect(config.content).to eq(content_result)
        end

        context 'when pipeline is downstream of a bridge' do
          let(:bridge) { create(:ci_bridge) }

          it 'does include compliance pipeline configuration' do
            expect(config.source).to eq(:compliance_source)
            expect(config.content).to eq(content_result)
          end

          context 'when pipeline source is parent pipeline' do
            let(:source) { :parent_pipeline }

            it_behaves_like 'does not include compliance pipeline configuration content'
          end
        end
      end

      context 'when compliance pipeline configuration is not defined' do
        let(:framework) { create(:compliance_framework, namespace: compliance_group) }
        let!(:framework_project_setting) do
          create(:compliance_framework_project_setting, project: project, compliance_management_framework: framework)
        end

        it_behaves_like 'does not include compliance pipeline configuration content'
      end

      context 'when compliance pipeline configuration is empty' do
        let(:framework) do
          create(:compliance_framework, namespace: compliance_group, pipeline_configuration_full_path: '')
        end

        let!(:framework_project_setting) do
          create(:compliance_framework_project_setting, project: project, compliance_management_framework: framework)
        end

        it_behaves_like 'does not include compliance pipeline configuration content'
      end
    end

    context 'when feature is not licensed' do
      before do
        stub_licensed_features(evaluate_group_level_compliance_pipeline: false)
      end

      it_behaves_like 'does not include compliance pipeline configuration content'
    end
  end

  context 'when project does not have compliance label defined' do
    context 'when feature is available' do
      before do
        stub_licensed_features(evaluate_group_level_compliance_pipeline: true)
      end

      it_behaves_like 'does not include compliance pipeline configuration content'
    end

    context 'when project has active scan_execution policies' do
      let(:security_policies) { { enabled: true, policies: [security_policy_configuration] } }
      let!(:security_policy_configuration) do
        create(:security_orchestration_policy_configuration, project: project)
      end

      let(:policy) { build(:scan_execution_policy, enabled: true, rules: [rule]) }
      let(:branches) { %w[master production] }

      before do
        allow(project).to receive(:all_security_orchestration_policy_configurations)
                            .and_return([security_policy_configuration])

        allow(security_policy_configuration).to receive(:active_scan_execution_policies).and_return([policy])
      end

      context 'when policies should be enforced' do
        context 'when security_orchestration_policies feature is available' do
          before do
            stub_licensed_features(security_orchestration_policies: true)
          end

          let(:security_policy_default_content) { YAML.dump(nil) }

          context 'when auto devops is not enabled' do
            before do
              stub_application_setting(auto_devops_enabled: false)
            end

            context 'when active policies includes a rule with pipeline type' do
              let(:rule) { { type: 'pipeline', branches: branches } }

              it 'includes security policies default pipeline configuration content' do
                expect(config.source).to eq(:security_policies_default_source)
                expect(config.content).to eq(security_policy_default_content)
              end
            end
          end
        end
      end

      context 'when policies should not be enforced' do
        let(:rule) { { type: 'schedule', branches: branches, cadence: '*/20 * * * *' } }

        context 'when security_orchestration_policies feature is not available' do
          context 'when auto devops is not enabled' do
            before do
              stub_application_setting(auto_devops_enabled: false)
            end

            it 'does not includes security policies default pipeline configuration content' do
              expect(config.source).to eq(nil)
            end
          end
        end

        context 'when auto devops is enabled' do
          it 'does not includes security policies default pipeline configuration content' do
            expect(config.source).to eq(:auto_devops_source)
          end
        end

        context 'when auto devops is not enabled' do
          before do
            stub_application_setting(auto_devops_enabled: false)
          end

          context 'when scan_execution_policy_pipelines feature is disabled' do
            before do
              stub_feature_flags(scan_execution_policy_pipelines: false)
            end

            it 'does not includes security policies default pipeline configuration content' do
              expect(config.source).to eq(nil)
            end
          end

          context 'when active policies does not includes a rule with pipeline type' do
            let(:rule) { { type: 'pipeline', branches: branches } }

            it 'includes security policies default pipeline configuration content' do
              expect(config.source).to eq(nil)
            end
          end
        end
      end
    end
  end
end
