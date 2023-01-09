# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::ApprovalWorker, feature_category: :continuous_delivery do
  describe 'automatic deployment' do
    let_it_be(:project) { create(:project, :repository, :allow_pipeline_trigger_approve_deployment) }
    let(:environment) { create(:environment, project: project) }
    let(:deployment) { create(:deployment, status: :blocked, project: project, environment: environment) }
    let(:job_args) { [deployment.id, { 'user_id': deployment.user.id, 'status': 'approved' }] }

    before do
      stub_licensed_features(protected_environments: true)
      create(
        :protected_environment,
        name: environment.name,
        project: project,
        required_approval_count: 1,
        deploy_access_levels: [build(:protected_environment_deploy_access_level, user: deployment.user)]
      )

      allow_next_found_instance_of(Ci::Build) do |build|
        allow(build).to receive(:enqueue!)
      end
    end

    it_behaves_like 'an idempotent worker'

    it 'approves deployment' do
      expect { described_class.new.perform(*job_args) }.to change { deployment.reload.approvals.count }.from(0).to(1)
    end
  end
end
