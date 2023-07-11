# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployment do
  it { is_expected.to have_many(:approvals) }
  it { is_expected.to delegate_method(:needs_approval?).to(:environment) }

  describe '#waiting_for_approval?' do
    subject { deployment.waiting_for_approval? }

    let_it_be(:project) { create(:project, :repository) }

    let(:environment) { create(:environment, project: project) }
    let(:deployment) { create(:deployment, :blocked, project: project, environment: environment) }

    context 'when pending approval count is positive' do
      before do
        allow(deployment).to receive(:pending_approval_count).and_return(1)
      end

      it { is_expected.to eq(true) }
    end

    context 'when pending approval count is zero' do
      before do
        allow(deployment).to receive(:pending_approval_count).and_return(0)
      end

      it { is_expected.to eq(false) }
    end

    context 'when dynamically_compute_deployment_approval feature flag is disabled' do
      before do
        stub_feature_flags(dynamically_compute_deployment_approval: false)
      end

      it { is_expected.to eq(true) }

      context 'with a deployment that is not waiting for approval' do
        let(:deployment) { create(:deployment, :success, project: project, environment: environment) }

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#pending_approval_count' do
    let_it_be(:project) { create(:project, :repository) }

    let(:environment) { create(:environment, project: project) }
    let(:deployment) { create(:deployment, :blocked, project: project, environment: environment) }

    let(:protected_environment) do
      create(:protected_environment, name: environment.name, project: project, required_approval_count: 3)
    end

    context 'when Protected Environments feature is available' do
      before do
        stub_licensed_features(protected_environments: true)
        protected_environment
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

      context 'when dynamically_compute_deployment_approval feature flag is disabled' do
        before do
          stub_feature_flags(dynamically_compute_deployment_approval: false)
        end

        context 'with a deployment that is not waiting for approval' do
          let(:deployment) { create(:deployment, :success, project: project, environment: environment) }

          it 'returns zero' do
            expect(deployment.pending_approval_count).to eq(0)
          end
        end
      end

      context 'with a protected environment that does not require approval' do
        let(:protected_environment) do
          create(:protected_environment, name: environment.name, project: project, required_approval_count: 0)
        end

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
