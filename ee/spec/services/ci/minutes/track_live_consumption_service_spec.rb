# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::TrackLiveConsumptionService, :saas, feature_category: :continuous_integration do
  let(:project) { create(:project, :private, shared_runners_enabled: true, namespace: namespace) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:namespace) { create(:namespace, shared_runners_minutes_limit: 100) }
  let(:user) { create(:user) }
  let(:build) { create(:ci_build, :running, project: project, pipeline: pipeline, runner: runner, user: user) }
  let(:runner) { create(:ci_runner, :instance) }

  let(:service) { described_class.new(build) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    subject { service.execute }

    shared_examples 'returns early' do |error_message|
      it 'returns an error response' do
        response = subject

        expect(response).to be_error
        expect(response.message).to eq(error_message)
      end
    end

    shared_examples 'limit not exceeded' do |expected_balance, expected_consumption|
      it 'does not drop the build', :aggregate_failures do
        response = subject
        expect(response).to be_success
        expect(response.message).to eq('CI minutes limit not exceeded')
        expect(response.payload.fetch(:current_balance).round).to eq(expected_balance)

        expect(service.live_consumption.to_i).to eq(expected_consumption)
      end
    end

    shared_examples 'limit exceeded' do
      it 'drops the build' do
        response = subject
        expect(response).to be_success
        expect(response.message).to eq('Build dropped due to CI minutes limit exceeded')
        expect(response.payload.fetch(:current_balance).round).to eq(-1001)

        expect(build.reload).to be_failed
        expect(build.failure_reason).to eq('ci_quota_exceeded')

        expect(service.live_consumption.to_i).to eq(minutes_consumption)
      end

      it 'logs event' do
        allow(Gitlab::AppLogger).to receive(:info).and_call_original
        expect(Gitlab::AppLogger).to receive(:info).with(
          message: 'Build dropped due to CI minutes limit exceeded',
          namespace: project.root_namespace.name,
          project_path: project.full_path,
          build_id: build.id,
          user_id: user.id,
          username: user.username)

        subject
      end
    end

    context 'when build is not running' do
      let(:build) { create(:ci_build, :success) }

      it_behaves_like 'returns early', 'Build is not running'
    end

    context 'when runner is not of instance type' do
      let(:runner) { create(:ci_runner, :project) }

      it_behaves_like 'returns early', 'Cost factor not enabled for build'
    end

    context 'when cost factor is not enabled for build' do
      before do
        allow(build).to receive(:cost_factor_enabled?).and_return(false)
      end

      it_behaves_like 'returns early', 'Cost factor not enabled for build'
    end

    context 'when namespace has unlimited minutes' do
      before do
        usage = double('usage', quota_enabled?: false)
        allow(project).to receive(:ci_minutes_usage).and_return(usage)
      end

      it_behaves_like 'returns early', 'Cost factor not enabled for build'
    end

    context 'when build has not been tracked recently' do
      it 'considers the current consumption as zero' do
        response = subject
        expect(response).to be_success
        expect(response.message).to eq('Build consumption is zero')
      end
    end

    context 'when build has been tracked recently' do
      before do
        service.time_last_tracked_consumption!(1.minute.ago.utc)
      end

      it_behaves_like 'limit not exceeded', 99, 1
    end

    context 'when current consumption exceeds the limit but not the grace period' do
      before do
        service.time_last_tracked_consumption!(200.minutes.ago.utc)
      end

      it_behaves_like 'limit not exceeded', -100, 200
    end

    context 'when current consumption exceeds the limit and the grace period' do
      let(:minutes_consumption) do
        namespace.shared_runners_minutes_limit + described_class::CONSUMPTION_THRESHOLD.abs + 1
      end

      before do
        service.time_last_tracked_consumption!(minutes_consumption.minutes.ago.utc)
      end

      it_behaves_like 'limit exceeded'

      context 'when namespace is on a trial hosted plan' do
        before do
          create(:gitlab_subscription, :premium, :active_trial, namespace: namespace)
        end

        it_behaves_like 'limit exceeded'
      end

      context 'when namespace is on a paid plan' do
        before do
          create(:gitlab_subscription, :premium, namespace: namespace)
        end

        it_behaves_like 'limit exceeded'
      end
    end
  end

  describe '#live_consumption', :clean_gitlab_redis_shared_state do
    subject { service.live_consumption }

    context 'when build has not been tracked' do
      it { is_expected.to be_zero }
    end

    context 'when build has been tracked once' do
      it 'returns the consumption since last update' do
        freeze_time do
          service.time_last_tracked_consumption!(3.minutes.ago)
          service.execute

          expect(subject).to eq(3.0)
        end
      end
    end

    context 'when build has been tracked multiple times' do
      before do
        service.time_last_tracked_consumption!(7.minutes.ago)

        travel_to 5.minutes.ago do
          service.execute # track 2 min
        end

        service.execute # track 5 min

        travel_to 10.minutes.from_now do
          service.execute # track 10 min
        end
      end

      it 'accumulates the consumption over different runs' do
        expect(subject.to_i).to eq(17)
      end
    end
  end
end
