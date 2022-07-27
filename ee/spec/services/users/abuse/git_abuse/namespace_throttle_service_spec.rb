# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::Abuse::GitAbuse::NamespaceThrottleService, :clean_gitlab_redis_rate_limiting do
  describe '.execute' do
    let_it_be(:limit) { 3 }
    let_it_be(:time_period_in_seconds) { 60 }

    let_it_be(:owner) { create(:user) }
    let(:user) { create(:user) }
    let(:project) { create(:project, namespace: namespace) }

    let_it_be(:namespace) do
      create(
        :group,
        namespace_settings: create(:namespace_settings,
          unique_project_download_limit: limit,
          unique_project_download_limit_interval_in_seconds: time_period_in_seconds
        )
      )
    end

    subject(:execute) { described_class.execute(project, user) }

    before do
      namespace.add_owner(owner)
    end

    shared_examples 'sends email notification to namespace owners' do
      it 'sends email notification to namespace owners', :aggregate_failures do
        double = instance_double(ActionMailer::MessageDelivery, deliver_later: nil)
        expect(Notify).to receive(:user_auto_banned_email)
          .once
          .with(
            owner.id,
            user.id,
            max_project_downloads: limit,
            within_seconds: time_period_in_seconds,
            group: namespace
          )
          .and_return(double)

        execute
      end
    end

    context 'when user downloads the same project multiple times within the set time period for a namespace' do
      before do
        (limit + 1).times { described_class.execute(project, user) }
      end

      it { is_expected.to include(banned: false) }

      it 'does not ban the user' do
        execute

        expect(user.banned_from_namespace?(namespace)).to eq(false)
      end
    end

    context 'when user exceeds the download limit within the set time period for a namespace' do
      before do
        stub_feature_flags(auto_ban_user_on_namespace_excessive_projects_download: true)
        limit.times { described_class.execute(build_stubbed(:project, namespace: namespace), user) }
      end

      it { is_expected.to include(banned: true) }

      it_behaves_like 'sends email notification to namespace owners'

      it 'bans the user' do
        execute

        expect(user.banned_from_namespace?(namespace)).to eq(true)
      end

      it 'logs the event', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:info).with(
          message: "User exceeded max projects download within set time period for namespace",
          username: user.username,
          max_project_downloads: limit,
          time_period_s: time_period_in_seconds,
          namespace_id: namespace.id
        )

        expect(Gitlab::AppLogger).to receive(:info).with({
          message: "Namespace-level user ban",
          username: user.username,
          email: user.email,
          namespace_id: namespace.id,
          ban_by: described_class.name
        })

        execute
      end

      it 'sends email to admins only once' do
        execute

        expect(Notify).not_to receive(:user_auto_banned_email)
      end
    end

    context 'when owner exceeds the download limit within the set time period for a namespace' do
      let(:user) { owner }

      before do
        stub_feature_flags(auto_ban_user_on_namespace_excessive_projects_download: true)
        limit.times { described_class.execute(build_stubbed(:project, namespace: namespace), owner) }
      end

      it { is_expected.to include(banned: false) }

      it_behaves_like 'sends email notification to namespace owners'

      it 'does not ban the user' do
        execute

        expect(owner.banned_from_namespace?(namespace)).to eq(false)
      end

      it 'logs the notification event but not the ban event', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:info).with(
          message: "User exceeded max projects download within set time period for namespace",
          username: owner.username,
          max_project_downloads: limit,
          time_period_s: time_period_in_seconds,
          namespace_id: namespace.id
        )

        expect(Gitlab::AppLogger).not_to receive(:info).with({
          message: "Namespace-level user ban",
          username: owner.username,
          email: owner.email,
          namespace_id: namespace.id,
          ban_by: described_class.name
        })

        execute
      end
    end

    context 'when auto_ban_user_on_namespace_excessive_projects_download feature flag is disabled' do
      before do
        stub_feature_flags(auto_ban_user_on_namespace_excessive_projects_download: false)
        limit.times { described_class.execute(build_stubbed(:project, namespace: namespace), user) }
      end

      it { is_expected.to include(banned: false) }

      it_behaves_like 'sends email notification to namespace owners'

      it 'does not ban the user' do
        execute

        expect(user.banned_from_namespace?(namespace)).to eq(false)
      end

      it 'logs the notification event but not the ban event' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          message: "User exceeded max projects download within set time period for namespace",
          username: user.username,
          max_project_downloads: limit,
          time_period_s: time_period_in_seconds,
          namespace_id: namespace.id
        )

        expect(Gitlab::AppLogger).not_to receive(:info).with(
          message: "Namespace-level user ban",
          username: user.username,
          namespace_id: namespace.id,
          ban_by: described_class.name
        )

        execute
      end
    end

    context 'when user is already banned' do
      before do
        create(:namespace_ban, namespace: namespace, user: user)
        limit.times { described_class.execute(build_stubbed(:project, namespace: namespace), user) }
      end

      it { is_expected.to include(banned: true) }
    end
  end
end
