# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::CreatePipelineService do
  describe '#execute' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:current_user) { project.owner }
    let_it_be(:branch) { project.default_branch }
    let_it_be(:action) { { scan: 'secret_detection' } }
    let_it_be(:service) do
      described_class.new(project: project, current_user: current_user, params: {
        action: action, branch: branch
      })
    end

    subject { service.execute }

    context 'when scan type is valid' do
      let(:status) { subject[:status] }
      let(:pipeline) { subject[:payload] }
      let(:message) { subject[:message] }

      context 'when action is valid' do
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
      end
    end
  end
end
