# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployment do
  it { is_expected.to have_many(:approvals) }
  it { is_expected.to delegate_method(:needs_approval?).to(:environment) }

  describe 'state machine' do
    context 'when deployment blocked' do
      let(:deployment) { create(:deployment) }

      before do
        allow(deployment).to receive(:allow_pipeline_trigger_approve_deployment).and_return(true)
      end

      it 'schedules Deployments::ApprovalWorker' do
        freeze_time do
          expect(::Deployments::ApprovalWorker).to receive(:perform_async).with(
            deployment.id,
            user_id: deployment.user_id,
            status: 'approved'
          )
          deployment.block!
        end
      end
    end
  end

  describe '#pending_approval_count' do
    let_it_be(:project) { create(:project, :repository) }

    let(:environment) { create(:environment, project: project) }
    let(:deployment) { create(:deployment, :blocked, project: project, environment: environment) }

    context 'when Protected Environments feature is available' do
      before do
        stub_licensed_features(protected_environments: true)
        create(:protected_environment, name: environment.name, project: project, required_approval_count: 3)
      end

      context 'with no approvals' do
        it 'returns the number of approvals required by the environment' do
          expect(deployment.pending_approval_count).to eq(3)
        end
      end

      context 'with some approvals' do
        before do
          create(:deployment_approval, deployment: deployment)
        end

        it 'returns the number of pending approvals' do
          expect(deployment.pending_approval_count).to eq(2)
        end
      end

      context 'with all approvals satisfied' do
        before do
          create_list(:deployment_approval, 3, deployment: deployment)
        end

        it 'returns zero' do
          expect(deployment.pending_approval_count).to eq(0)
        end
      end

      context 'with a deployment that is not blocked' do
        let(:deployment) { create(:deployment, :success, project: project, environment: environment) }

        it 'returns zero' do
          expect(deployment.pending_approval_count).to eq(0)
        end
      end

      context 'loading approval count' do
        before do
          deployment.environment.required_approval_count
          deployment.approvals.to_a
        end

        it 'does not perform an extra query when approvals are loaded', :request_store do
          expect { deployment.pending_approval_count }.not_to exceed_query_limit(0)
        end
      end
    end

    context 'when Protected Environments feature is not available' do
      before do
        stub_licensed_features(protected_environments: false)
      end

      it 'returns zero' do
        expect(deployment.pending_approval_count).to eq(0)
      end
    end
  end
end
