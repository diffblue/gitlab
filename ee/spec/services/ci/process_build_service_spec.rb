# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::ProcessBuildService, '#execute' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:environment) { create(:environment, project: project, name: 'production') }
  let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }
  let(:ci_build) { create(:ci_build, :created, environment: environment.name, user: user, project: project, when: :on_success) }
  let(:current_status) { 'success' }

  subject { described_class.new(project, user).execute(ci_build, current_status) }

  before do
    stub_licensed_features(protected_environments: feature_available)

    protected_environment
  end

  context 'when related to a protected environment' do
    context 'when Protected Environments feature is not available on project' do
      let(:feature_available) { false }

      it 'enqueues the build' do
        subject

        expect(ci_build.pending?).to be_truthy
      end
    end

    context 'when Protected Environments feature is available on project' do
      let(:feature_available) { true }

      context 'when user does not have access to the environment' do
        it 'fails the build' do
          allow(Deployments::LinkMergeRequestWorker).to receive(:perform_async)
          allow(Deployments::HooksWorker).to receive(:perform_async)
          subject

          expect(ci_build.failed?).to be_truthy
          expect(ci_build.failure_reason).to eq('protected_environment_failure')
        end

        context 'and the build is manual' do
          let(:ci_build) { create(:ci_build, :created, :actionable, environment: environment.name, user: user, project: project) }

          it 'actionizes the build' do
            expect { subject }.to change { ci_build.status }.from('created').to('manual')
          end
        end
      end

      context 'when user has access to the environment' do
        before do
          protected_environment.deploy_access_levels.create!(user: user)
        end

        it 'enqueues the build' do
          subject

          expect(ci_build.pending?).to be_truthy
        end

        context 'and environment needs approval' do
          before do
            protected_environment.update!(required_approval_count: 1)
          end

          it 'makes the build a manual action' do
            expect { subject }.to change { ci_build.status }.from('created').to('manual')
          end

          context 'and the build has a deployment' do
            shared_examples_for 'blocked deployment' do
              it 'blocks the deployment' do
                expect { subject }.to change { deployment.reload.status }.from('created').to('blocked')
              end

              it 'makes the build a manual action' do
                expect { subject }.to change { ci_build.status }.from('created').to('manual')
              end
            end

            let!(:deployment) { create(:deployment, deployable: ci_build, environment: environment, user: user, project: project) }

            include_examples 'blocked deployment'

            context 'and the build is schedulable' do
              let(:ci_build) { create(:ci_build, :created, :schedulable, environment: environment.name, user: user, project: project) }

              include_examples 'blocked deployment'
            end

            context 'and the build is actionable' do
              let(:ci_build) { create(:ci_build, :created, :actionable, environment: environment.name, user: user, project: project) }

              include_examples 'blocked deployment'
            end
          end
        end
      end
    end
  end
end
