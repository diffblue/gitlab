# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployment do
  it { is_expected.to have_many(:approvals) }
  it { is_expected.to delegate_method(:needs_approval?).to(:environment) }

  describe 'state machine' do
    context 'when deployment succeeded' do
      let(:deployment) { create(:deployment, :running) }

      it 'schedules Dora::DailyMetrics::RefreshWorker' do
        freeze_time do
          expect(::Dora::DailyMetrics::RefreshWorker)
            .to receive(:perform_in).with(
              5.minutes,
              deployment.environment_id,
              Time.current.to_date.to_s)

          deployment.succeed!
        end
      end
    end
  end

  describe '#sync_status_with' do
    subject { deployment.sync_status_with(ci_build) }

    let_it_be(:project) { create(:project, :repository) }

    let(:environment) { create(:environment, project: project) }
    let(:deployment) { create(:deployment, project: project, environment: environment) }

    context 'when build is manual' do
      let(:ci_build) { create(:ci_build, project: project, status: :manual) }

      context 'and Protected Environments feature is available' do
        before do
          stub_licensed_features(protected_environments: true)
          create(:protected_environment, name: environment.name, project: project, required_approval_count: required_approval_count)
        end

        context 'and deployment needs approval' do
          let(:required_approval_count) { 1 }

          it 'blocks the deployment' do
            expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

            is_expected.to eq(true)

            expect(deployment.status).to eq('blocked')
            expect(deployment.errors).to be_empty
          end
        end

        context 'and deployment does not need approval' do
          let(:required_approval_count) { 0 }

          it 'does not change the deployment' do
            expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

            is_expected.to eq(false)

            expect(deployment.status).to eq('created')
            expect(deployment.errors).to be_empty
          end
        end
      end

      context 'and Protected Environments feature is not available' do
        before do
          stub_licensed_features(protected_environments: false)
        end

        it 'does not change the deployment' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          is_expected.to eq(false)

          expect(deployment.status).to eq('created')
          expect(deployment.errors).to be_empty
        end
      end
    end
  end

  describe '#pending_approval_count' do
    let_it_be(:project) { create(:project, :repository) }

    let(:environment) { create(:environment, project: project) }
    let(:deployment) { create(:deployment, project: project, environment: environment) }

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
