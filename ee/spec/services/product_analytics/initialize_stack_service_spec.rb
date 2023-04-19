# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::InitializeStackService, :clean_gitlab_redis_shared_state,
  feature_category: :product_analytics do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    stub_feature_flags(product_analytics_snowplow_support: false)
  end

  shared_examples 'no job is enqueued' do
    it 'does not enqueue a job' do
      expect(::ProductAnalytics::InitializeAnalyticsWorker).not_to receive(:perform_async)

      subject
    end
  end

  describe '#lock!' do
    subject { described_class.new(container: project, current_user: user).lock! }

    it 'sets the redis key' do
      expect { subject }
        .to change {
          described_class.new(container: project, current_user: user).send(:locked?)
        }.from(false).to(true)
    end
  end

  describe '#unlock!' do
    subject { described_class.new(container: project, current_user: user).unlock! }

    it 'deletes the redis key' do
      subject

      expect(described_class.new(container: project, current_user: user).send(:locked?)).to eq false
    end
  end

  describe '#execute' do
    subject { described_class.new(container: project, current_user: user).execute }

    before do
      stub_licensed_features(product_analytics: true)
      stub_ee_application_setting(product_analytics_enabled: true)
    end

    context 'when snowplow support is enabled' do
      before do
        stub_feature_flags(product_analytics_snowplow_support: true)
      end

      it 'enqueues a job' do
        expect(::ProductAnalytics::InitializeSnowplowProductAnalyticsWorker)
          .to receive(:perform_async).with(project.id)

        described_class.new(container: project, current_user: user).execute
      end

      context 'when project is already initialized for product analytics' do
        before do
          project.project_setting.update!(product_analytics_instrumentation_key: '123')
        end

        it 'returns an error response' do
          expect(subject).to be_error
          expect(subject.message).to eq('Product analytics initialization is already complete')
        end
      end
    end

    context 'when feature flag is enabled' do
      it 'enqueues a job' do
        expect(::ProductAnalytics::InitializeAnalyticsWorker).to receive(:perform_async).with(project.id)

        subject
      end

      it 'locks the job' do
        subject

        expect(described_class.new(container: project, current_user: user).send(:locked?)).to eq true
      end

      it 'returns a success response' do
        expect(subject).to be_success
        expect(subject.message).to eq('Product analytics initialization started')
      end

      context 'when initialization is already in progress' do
        before do
          Gitlab::Redis::SharedState.with do |redis|
            redis.set("project:#{project.id}:product_analytics_initializing", 1)
          end
        end

        it 'returns an error stating that initialization is already in progress' do
          expect(subject).to be_error
          expect(subject.message).to eq('Product analytics initialization is already in progress')
        end
      end

      context 'when initialization is already complete' do
        before do
          project.project_setting.update!(jitsu_key: '123')
        end

        it 'returns an error response' do
          expect(subject).to be_error
          expect(subject.message).to eq('Product analytics initialization is already complete')
        end
      end
    end

    context 'when product analytics is disabled per project' do
      before do
        allow(project).to receive(:product_analytics_enabled?).and_return(false)
      end

      it_behaves_like 'no job is enqueued'

      it 'returns an error' do
        expect(subject.message).to eq "Product analytics is disabled for this project"
      end
    end

    context 'when product analytics is disabled at instance level' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:product_analytics_enabled?).and_return(false)
      end

      it_behaves_like 'no job is enqueued'

      it 'returns an error' do
        expect(subject.message).to eq "Product analytics is disabled"
      end
    end

    context 'when user does not have permission to initialize product analytics' do
      before do
        project.add_guest(user)
      end

      it_behaves_like 'no job is enqueued'
    end

    context 'when enable_product_analytics application setting is false' do
      before do
        stub_ee_application_setting(product_analytics_enabled: false)
      end

      it_behaves_like 'no job is enqueued'
    end
  end
end
