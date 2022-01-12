# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::CreatePipelineService do
  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project, :repository) }
    let_it_be(:current_user) { project.owner }
    let_it_be(:branch) { project.default_branch }

    let(:action) { { scan: 'secret_detection' } }
    let(:scan_type) { action[:scan] }

    let(:service) do
      described_class.new(project: project, current_user: current_user, params: {
        action: action, branch: branch
      })
    end

    subject { service.execute }

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

        context 'for cluster_image_scanning scan' do
          let_it_be(:cluster) { create(:cluster, :provided_by_user, name: 'production') }
          let_it_be(:cluster_project) { create(:cluster_project, cluster: cluster, project: project) }
          let_it_be(:environment) { create(:environment, name: 'environment-name', project: project) }
          let_it_be(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, cluster: cluster, cluster_project: cluster_project, project: project, environment: environment) }

          let(:action) { { scan: 'cluster_image_scanning', clusters: { production: { namespaces: ['gitlab-namespace'] } } } }

          it_behaves_like 'valid security orchestration policy action'

          it 'sets the build name to cluster_image_scanning' do
            build = pipeline.builds.first

            expect(build.name).to eq('cluster_image_scanning')
          end

          it 'creates a build with appropriate variables' do
            build = pipeline.builds.first

            expected_variables = [
              hash_including(
                key: 'CIS_KUBECONFIG',
                public: false,
                masked: false
              ),
              {
                key: 'CIS_RESOURCE_NAMESPACES',
                masked: false,
                public: true,
                value: 'gitlab-namespace'
              }
            ]

            expect(build.variables.to_runner_variables).to include(*expected_variables)
          end
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
                expect(ci_configuration_service).to receive(:execute).once.with(action, 'SAST_DISABLED' => nil, 'SAST_EXCLUDED_ANALYZERS' => 'semgrep').and_call_original
              end

              subject
            end
          end
        end
      end
    end
  end
end
