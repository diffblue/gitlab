# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::AutoRollbackService, :clean_gitlab_redis_rate_limiting, feature_category: :continuous_delivery do
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:project, refind: true) { create(:project, :repository) }
  let_it_be(:environment, refind: true) { create(:environment, project: project) }
  let_it_be(:commits) { project.repository.commits('master', limit: 2) }

  let(:service) { described_class.new(project, nil) }

  before_all do
    project.add_maintainer(maintainer)
    project.ci_forward_deployment_enabled = false
    project.update!(auto_rollback_enabled: true)
  end

  shared_examples_for 'rollback failure' do
    it 'returns an error' do
      expect(subject[:status]).to eq(:error)
      expect(subject[:message]).to eq(message)
    end
  end

  describe '#execute' do
    subject { service.execute(environment) }

    before do
      stub_licensed_features(auto_rollback: true)
      commits.reverse_each { |commit| create_deployment(commit.id) }
    end

    it 'successfully rolls back a deployment' do
      expect { subject }.to change { Deployment.count }.by(1)

      expect(subject[:status]).to eq(:success)
      expect(subject[:deployment].sha).to eq(commits[1].id)
    end

    context 'when RetryJobService fails to retry the deployable' do
      before do
        allow_next_instance_of(::Ci::RetryJobService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: message))
        end
      end

      it_behaves_like 'rollback failure' do
        let(:message) { 'Job cannot be retried.' }
      end
    end

    context 'when auto_rollback checkbox is disabled on the project' do
      before do
        environment.project.auto_rollback_enabled = false
      end

      it_behaves_like 'rollback failure' do
        let(:message) { 'Auto Rollback is not enabled on the project.' }
      end
    end

    context 'when project does not have an sufficient license' do
      before do
        stub_licensed_features(auto_rollback: false)
      end

      it_behaves_like 'rollback failure' do
        let(:message) { 'Auto Rollback is not enabled on the project.' }
      end
    end

    context 'when there are running deployments ' do
      before do
        create(:deployment, :running, environment: environment)
      end

      it_behaves_like 'rollback failure' do
        let(:message) { 'There are running deployments on the environment.' }
      end
    end

    context 'when auto rollback was triggered recently' do
      before do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?) { true }
      end

      it_behaves_like 'rollback failure' do
        let(:message) { 'Auto Rollback was recentlly trigged for the environment. It will be re-activated after a minute.' }
      end
    end

    context 'when there are no deployments on the environment' do
      before do
        environment.deployments.fast_destroy_all
      end

      it_behaves_like 'rollback failure' do
        let(:message) { 'Failed to find a rollback target.' }
      end
    end

    context 'when there are no deployed commits in the repository' do
      before do
        environment.last_deployment.update!(sha: 'not-exist')
      end

      it_behaves_like 'rollback failure' do
        let(:message) { 'Failed to find a rollback target.' }
      end
    end

    context "when rollback target's deployable is not available" do
      before do
        environment.all_deployments.first.deployable.destroy!
      end

      it_behaves_like 'rollback failure' do
        let(:message) { 'Failed to find a rollback target.' }
      end
    end

    context "when rollback target's deployable is not retryable" do
      before do
        environment.all_deployments.first.deployable.degenerate!
      end

      it_behaves_like 'rollback failure' do
        let(:message) { 'Failed to find a rollback target.' }
      end
    end

    context "when the user who performed deployments is no longer a project member" do
      let(:external_user) { create(:user) }

      before do
        environment.all_deployments.first.deployable.update!(user: external_user)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    def create_deployment(commit_id)
      attributes = { project: project, ref: 'master', user: maintainer }
      pipeline = create(:ci_pipeline, :success, sha: commit_id, **attributes)
      build = create(:ci_build, :success, pipeline: pipeline, environment: environment.name, **attributes)
      create(:deployment, :success, environment: environment, deployable: build, sha: commit_id, **attributes)
    end
  end
end
