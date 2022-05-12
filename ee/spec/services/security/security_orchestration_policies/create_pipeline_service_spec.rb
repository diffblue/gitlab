# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::CreatePipelineService do
  include AfterNextHelpers

  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project, :repository) }
    let_it_be(:current_user) { project.first_owner }
    let_it_be(:branch) { project.default_branch }
    let_it_be(:license) { create(:license, plan: License::ULTIMATE_PLAN) }

    let(:action) { { scan: 'secret_detection' } }
    let(:scan_type) { action[:scan] }

    let(:service) do
      described_class.new(project: project, current_user: current_user, params: {
        action: action, branch: branch
      })
    end

    subject { service.execute }

    before do
      allow(License).to receive(:current).and_return(license)
      stub_licensed_features(cluster_image_scanning: true, container_scanning: true)
    end

    shared_examples 'valid security orchestration policy action' do
      it 'returns a success status' do
        expect(status).to eq(:success)
      end

      it 'returns a pipeline' do
        expect(pipeline).to be_a(Ci::Pipeline)
      end

      it 'creates a pipeline' do
        expect { subject }.to change(Ci::Pipeline, :count).by(1)
      end

      it 'sets the pipeline ref to the branch' do
        expect(pipeline.ref).to eq(branch)
      end

      it 'sets the source to security_orchestration_policy' do
        expect(pipeline.source).to eq('security_orchestration_policy')
      end

      it 'creates a stage' do
        expect { subject }.to change(Ci::Stage, :count).by(1)
      end

      it 'creates a build' do
        expect { subject }.to change(Ci::Build, :count).by(1)
      end
    end

    context 'when scan type is valid' do
      let(:status) { subject[:status] }
      let(:pipeline) { subject[:payload] }
      let(:message) { subject[:message] }

      context 'when action is valid' do
        it_behaves_like 'valid security orchestration policy action'

        it 'sets the build name to secret_detection' do
          build = pipeline.builds.first
          expect(build.name).to eq('secret_detection')
        end

        it 'creates a build with appropriate variables' do
          build = pipeline.builds.first

          expected_variables = [
            {
              key: 'SECRET_DETECTION_HISTORIC_SCAN',
              value: 'true',
              public: true,
              masked: false
            }
          ]

          expect(build.variables.to_runner_variables).to include(*expected_variables)
        end

        context 'for container_scanning scan' do
          let(:action) { { scan: 'container_scanning' } }

          it_behaves_like 'valid security orchestration policy action'

          it 'sets the build name to container_scanning' do
            build = pipeline.builds.first

            expect(build.name).to eq('container_scanning')
          end
        end

        context 'for sast scan' do
          let(:action) { { scan: 'sast' } }

          it 'sets the build name to sast' do
            build = pipeline.bridges.first

            expect(build.name).to eq('sast')
          end

          context 'when action contains variables' do
            let(:action) { { scan: 'sast', variables: { SAST_EXCLUDED_ANALYZERS: 'semgrep' } } }

            it 'parses variables from the action and applies them in configuration service' do
              expect_next_instance_of(::Security::SecurityOrchestrationPolicies::CiConfigurationService) do |ci_configuration_service|
                expect(ci_configuration_service).to receive(:execute).once
                  .with(action, { 'SAST_DISABLED' => nil, 'SAST_EXCLUDED_ANALYZERS' => 'semgrep' }).and_call_original
              end

              subject
            end
          end
        end
      end

      context "when project has a compliance framework" do
        let(:compliance_group) { create(:group, :private, name: "compliance") }
        let(:compliance_project) { create(:project, :repository, namespace: compliance_group, name: "hippa") }
        let(:framework) { create(:compliance_framework, namespace_id: compliance_group.id, pipeline_configuration_full_path: ".compliance-gitlab-ci.yml@compliance/hippa") }
        let!(:framework_project_setting) { create(:compliance_framework_project_setting, project: project, framework_id: framework.id) }
        let!(:ref_sha) { compliance_project.commit('HEAD').sha }

        let(:compliance_config) do
          <<~EOY
          ---
          compliance_build:
            stage: build
            script:
              - echo 'hello from compliance build'
          compliance_test:
            stage: test
            script:
              - echo 'hello from compliance test'
          EOY
        end

        before do
          project.update_attribute(:namespace_id, compliance_group.id)
          compliance_project.add_maintainer(current_user)
          stub_licensed_features(cluster_image_scanning: true, container_scanning: true, evaluate_group_level_compliance_pipeline: true)
          allow_next(Repository).to receive(:blob_data_at).with(ref_sha, '.compliance-gitlab-ci.yml').and_return(compliance_config)
        end

        it 'does not include the compliance definition' do
          subject

          yaml = YAML.safe_load(pipeline.pipeline_config.content, [Symbol])
          expect(yaml).not_to eq("include" => [{ "file" => ".compliance-gitlab-ci.yml", "project" => "compliance/hippa" }])
        end
      end
    end
  end
end
