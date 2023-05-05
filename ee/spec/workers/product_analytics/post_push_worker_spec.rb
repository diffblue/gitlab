# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::PostPushWorker, feature_category: :product_analytics do
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:commit) { project.repository.commit }

  subject { described_class.new.perform(project.id, commit.sha, user.id) }

  shared_examples 'tracks a usage event' do
    it 'tracks a project usage event' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter)
        .to receive(:track_usage_event).twice.with(an_instance_of(String), an_instance_of(Integer))

      subject
    end
  end

  shared_examples 'does not track a usage event' do
    it 'does not track a usage event' do
      expect(Gitlab::Utils::UsageData).not_to receive(:track_usage_event)

      subject
    end
  end

  context 'when the commit includes a new dashboard' do
    before do
      create_new_dashboard
    end

    it_behaves_like 'tracks a usage event'
  end

  context 'when the commit includes a new file that is not a dashboard' do
    it_behaves_like 'does not track a usage event'
  end

  private

  def create_new_dashboard
    project.repository.create_file(
      project.creator,
      '.gitlab/analytics/dashboards/dashboard_hello/dashboard_hello.yml',
      'content',
      message: 'Add dashboard',
      branch_name: 'master'
    )
  end
end
