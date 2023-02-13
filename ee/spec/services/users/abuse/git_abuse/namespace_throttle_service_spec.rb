# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::Abuse::GitAbuse::NamespaceThrottleService, feature_category: :insider_threat do
  describe '.execute' do
    let_it_be(:limit) { 3 }
    let_it_be(:time_period_in_seconds) { 60 }
    let_it_be(:allowlist) { [] }

    let_it_be_with_reload(:namespace) do
      create(
        :group,
        namespace_settings: create(:namespace_settings,
          unique_project_download_limit: limit,
          unique_project_download_limit_interval_in_seconds: time_period_in_seconds,
          unique_project_download_limit_allowlist: allowlist,
          auto_ban_user_on_excessive_projects_download: true
        )
      )
    end

    let_it_be_with_reload(:user) { create(:user) }
    let_it_be(:namespace_admin) { create(:user) }
    let_it_be(:inactive_namespace_admin) { create(:user, :deactivated) }
    let_it_be(:project) { create(:project, namespace: namespace) }

    let(:mail_instance) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

    subject(:execute) { described_class.execute(user, project) }

    before do
      namespace.add_owner(namespace_admin)
      namespace.add_owner(inactive_namespace_admin)
    end

    context 'when user is not rate-limited' do
      before do
        mock_throttled_calls(project, peek_result: false, result: false)
      end

      it 'returns { banned: false }' do
        response = execute

        expect(response).to be_success
        expect(response.payload).to eq(banned: false)
      end

      it 'does not ban the user' do
        execute

        expect(user.banned_from_namespace?(namespace)).to eq(false)
      end
    end

    context 'when user is rate-limited' do
      before do
        mock_throttled_calls(project, peek_result: false, result: true)
      end

      it 'returns { banned: true }' do
        response = execute

        expect(response).to be_success
        expect(response.payload).to eq(banned: true)
      end

      it 'bans the user' do
        execute

        expect(user.banned_from_namespace?(namespace)).to eq(true)
      end

      it 'logs the event', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:info).with({
          message: "User exceeded max projects download within set time period for namespace",
          username: user.username,
          max_project_downloads: limit,
          time_period_s: time_period_in_seconds,
          namespace_id: namespace.id
        })

        expect(Gitlab::AppLogger).to receive(:info).with({
          message: "Namespace-level user ban",
          username: user.username,
          email: user.email,
          namespace_id: namespace.id,
          ban_by: described_class.name
        })

        execute
      end

      describe 'sending notifications' do
        shared_examples 'sends an email' do
          it do
            opts = {
              max_project_downloads: limit,
              within_seconds: time_period_in_seconds,
              auto_ban_enabled: true,
              group: namespace
            }

            expect(Notify).to receive(:user_auto_banned_email)
              .with(
                recipient.id,
                user.id,
                opts
              )
              .once
              .and_return(mail_instance)

            expect(Notify).not_to receive(:user_auto_banned_email)
              .with(
                inactive_namespace_admin.id,
                user.id,
                opts
              )

            expect(mail_instance).to receive(:deliver_later)

            execute
          end
        end

        it_behaves_like 'sends an email' do
          let(:recipient) { namespace_admin }
        end

        context 'when the alertlist is not empty' do
          let_it_be(:alertlisted_user) { create(:user) }

          before do
            namespace.namespace_settings.update!(unique_project_download_limit_alertlist: [alertlisted_user.id])
          end

          it_behaves_like 'sends an email' do
            let(:recipient) { alertlisted_user }
          end
        end
      end

      context 'when user downloads another project' do
        let(:another_project) { build_stubbed(:project, namespace: namespace) }

        before do
          mock_throttled_calls(another_project, peek_result: true, result: true)
        end

        it 'does not send another email to namespace admins', :mailer do
          expect(Notify).not_to receive(:user_auto_banned_email)

          described_class.execute(user, another_project)
        end
      end
    end

    context 'when namespace admin is rate-limited' do
      let(:user) { namespace_admin }

      before do
        mock_throttled_calls(project, peek_result: false, result: true)
      end

      it 'returns { banned: false }' do
        response = execute

        expect(response).to be_success
        expect(response.payload).to eq(banned: false)
      end

      it 'does not ban the user' do
        execute

        expect(user.banned_from_namespace?(namespace)).to eq(false)
      end

      it 'logs the notification event but not the ban event', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:info).with({
          message: "User exceeded max projects download within set time period for namespace",
          username: user.username,
          max_project_downloads: limit,
          time_period_s: time_period_in_seconds,
          namespace_id: namespace.id
        })

        expect(Gitlab::AppLogger).not_to receive(:info).with({
          message: "Namespace-level user ban",
          username: user.username,
          email: user.email,
          namespace_id: namespace.id,
          ban_by: described_class.name
        })

        execute
      end

      it 'sends an email to all namespace admins', :mailer do
        expect(Notify).to receive(:user_auto_banned_email)
          .with(
            namespace_admin.id,
            user.id,
            max_project_downloads: limit,
            within_seconds: time_period_in_seconds,
            auto_ban_enabled: true,
            group: namespace
          )
          .once
          .and_return(mail_instance)

        expect(mail_instance).to receive(:deliver_later)

        execute
      end
    end

    context 'when user is already banned and gets throttled' do
      before do
        create(:namespace_ban, namespace: namespace, user: user)
        mock_throttled_calls(project, peek_result: false, result: true)
      end

      it 'returns { banned: true }' do
        response = execute

        expect(response).to be_success
        expect(response.payload).to eq(banned: true)
      end

      it 'user remains banned' do
        execute

        expect(user.banned_from_namespace?(namespace)).to eq(true)
      end

      it 'logs a notification event and user already banned event', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:info).with({
          message: "User exceeded max projects download within set time period for namespace",
          username: user.username,
          max_project_downloads: limit,
          time_period_s: time_period_in_seconds,
          namespace_id: namespace.id
        })

        expect(Gitlab::AppLogger).not_to receive(:info).with({
          message: "Namespace-level user ban",
          username: user.username,
          email: user.email,
          namespace_id: namespace.id,
          ban_by: described_class.name
        })

        execute
      end
    end

    context 'when allowlisted user gets throttled' do
      let(:allowlist) { [user.username] }

      before do
        namespace.namespace_settings.update!(unique_project_download_limit_allowlist: allowlist)
        mock_throttled_calls(project, peek_result: false, result: false)
      end

      it 'returns { banned: false }' do
        response = execute

        expect(response).to be_success
        expect(response.payload).to eq(banned: false)
      end

      it 'does not ban the user' do
        execute

        expect(user.banned_from_namespace?(namespace)).to eq(false)
      end

      it 'does not log any event' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        execute
      end

      it 'does not send an email to namespace admins', :mailer do
        expect(Notify).not_to receive(:user_auto_banned_email)

        execute
      end
    end

    context 'when auto_ban_user_on_excessive_projects_download is disabled and user gets throttled' do
      before do
        namespace.namespace_settings.update!({
          auto_ban_user_on_excessive_projects_download: false
        })

        mock_throttled_calls(project, peek_result: false, result: true)
      end

      it 'returns { banned: false }' do
        response = execute

        expect(response).to be_success
        expect(response.payload).to eq(banned: false)
      end

      it 'does not ban the user' do
        execute

        expect(user.banned_from_namespace?(namespace)).to eq(false)
      end

      it 'logs the notification event but not the ban event', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:info).with({
          message: "User exceeded max projects download within set time period for namespace",
          username: user.username,
          max_project_downloads: limit,
          time_period_s: time_period_in_seconds,
          namespace_id: namespace.id
        })

        expect(Gitlab::AppLogger).not_to receive(:info).with({
          message: "Namespace-level user ban",
          username: user.username,
          email: user.email,
          namespace_id: namespace.id,
          ban_by: described_class.name
        })

        execute
      end

      it 'sends an email to namespace admins', :mailer do
        expect(Notify).to receive(:user_auto_banned_email)
          .with(
            namespace_admin.id,
            user.id,
            max_project_downloads: limit,
            within_seconds: time_period_in_seconds,
            auto_ban_enabled: false,
            group: namespace
          )
          .once
          .and_return(mail_instance)

        expect(mail_instance).to receive(:deliver_later)

        execute
      end
    end
  end

  private

  def mock_throttled_calls(resource, peek_result:, result:)
    key = :unique_project_downloads_for_namespace
    args = {
      scope: [user, namespace],
      resource: resource,
      threshold: limit,
      interval: time_period_in_seconds,
      users_allowlist: allowlist
    }

    allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?)
      .with(key, hash_including(args.merge(peek: true)))
      .and_return(peek_result)

    allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?)
      .with(key, hash_including(args.merge(peek: false)))
      .and_return(result)
  end
end
