# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::ProjectConfig do
  let(:project) { create(:project, ci_config_path: nil) }
  let(:sha) { '123456' }
  let(:content) { nil }
  let(:source) { :push }
  let(:bridge) { nil }

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
  end
end
