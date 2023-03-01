# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::Abuse::GitAbuse::ApplicationThrottleService, feature_category: :insider_threat do
  describe '.execute' do
    let_it_be(:limit) { 3 }
    let_it_be(:time_period_in_seconds) { 60 }
    let_it_be(:allowlist) { [] }
    let_it_be(:alertlist) { [] }

    let_it_be_with_reload(:user) { create(:user) }
    let_it_be(:admin) { create(:user, :admin) }
    let_it_be(:inactive_admin) { create(:user, :admin, :deactivated) }
    let_it_be(:project) { create(:project) }

    let(:mail_instance) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

    subject(:execute) { described_class.execute(user, project) }

    before do
      stub_application_setting(max_number_of_repository_downloads: limit)
      stub_application_setting(max_number_of_repository_downloads_within_time_period: time_period_in_seconds)
      stub_application_setting(git_rate_limit_users_allowlist: allowlist)
      stub_application_setting(auto_ban_user_on_excessive_projects_download: true)
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

        expect(user.banned?).to eq(false)
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

        expect(user.banned?).to eq(true)
      end

      it 'logs the event', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:info).with(
          {
            message: "User exceeded max projects download within set time period for application",
            username: user.username,
            max_project_downloads: limit,
            time_period_s: time_period_in_seconds
          }
        )

        expect(Gitlab::AppLogger).to receive(:info).with(
          {
            message: "Application-level user ban",
            user: user.username,
            email: user.email,
            ban_by: described_class.name
          }
        )

        execute
      end

      describe 'when admin is rate-limited', :enable_admin_mode do
        let(:user) { admin }

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

          expect(user.banned?).to eq(false)
        end
      end

      describe 'sending notifications' do
        shared_examples 'sends an email' do
          it do
            opts = {
              max_project_downloads: limit,
              within_seconds: time_period_in_seconds,
              auto_ban_enabled: true,
              group: nil
            }

            expect(Notify).to receive(:user_auto_banned_email).with(recipient.id, user.id, opts)
              .once.and_return(mail_instance)
            expect(mail_instance).to receive(:deliver_later)

            expect(Notify).not_to receive(:user_auto_banned_email).with(inactive_admin.id, user.id, opts)

            execute
          end
        end

        it_behaves_like 'sends an email' do
          let(:recipient) { admin }
        end

        context 'when the alertlist is not empty' do
          before do
            allow(Gitlab::CurrentSettings.current_application_settings)
              .to receive(:git_rate_limit_users_alertlist).and_return([user.id])
          end

          it_behaves_like 'sends an email' do
            let(:recipient) { user }
          end
        end
      end

      context 'when user downloads another project' do
        let(:another_project) { build_stubbed(:project) }

        before do
          mock_throttled_calls(another_project, peek_result: true, result: true)
        end

        it 'does not send another email to admins', :mailer do
          expect(Notify).not_to receive(:user_auto_banned_email)

          described_class.execute(user, another_project)
        end
      end
    end

    context 'when auto_ban_user_on_excessive_projects_download is disabled and user gets throttled' do
      before do
        stub_application_setting(auto_ban_user_on_excessive_projects_download: false)

        mock_throttled_calls(project, peek_result: false, result: true)
      end

      it 'returns { banned: false }' do
        response = execute

        expect(response).to be_success
        expect(response.payload).to eq(banned: false)
      end

      it 'does not ban the user' do
        execute

        expect(user.banned?).to eq(false)
      end

      it 'logs a notification event but not a ban event', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:info).with(
          {
            message: "User exceeded max projects download within set time period for application",
            username: user.username,
            max_project_downloads: limit,
            time_period_s: time_period_in_seconds
          }
        )

        expect(Gitlab::AppLogger).not_to receive(:info).with(
          {
            message: "Application-level user ban",
            user: user.username,
            email: user.email,
            ban_by: described_class.name
          }
        )

        execute
      end

      it 'sends an email to admins', :mailer do
        opts = {
          max_project_downloads: limit,
          within_seconds: time_period_in_seconds,
          auto_ban_enabled: false,
          group: nil
        }
        expect(Notify).to receive(:user_auto_banned_email).with(admin.id, user.id, opts).once.and_return(mail_instance)
        expect(mail_instance).to receive(:deliver_later)

        execute
      end
    end

    context 'when user is already banned and gets throttled' do
      before do
        user.ban!

        mock_throttled_calls(project, peek_result: false, result: true)
      end

      it 'returns { banned: true }' do
        response = execute

        expect(response).to be_success
        expect(response.payload).to eq(banned: true)
      end

      it 'logs a notification event and user already banned event', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:info).with(
          {
            message: "User exceeded max projects download within set time period for application",
            username: user.username,
            max_project_downloads: limit,
            time_period_s: time_period_in_seconds
          }
        )

        expect(Gitlab::AppLogger).to receive(:info).with(
          {
            message: "Invalid transition when banning: " \
              "Cannot transition state via :ban from :banned (Reason(s): State cannot transition via \"ban\")",
            user: user.username,
            email: user.email,
            ban_by: described_class.name
          }
        )

        execute
      end

      it 'sends an email to admins', :mailer do
        opts = {
          max_project_downloads: limit,
          within_seconds: time_period_in_seconds,
          auto_ban_enabled: true,
          group: nil
        }
        expect(Notify).to receive(:user_auto_banned_email).with(admin.id, user.id, opts).once.and_return(mail_instance)
        expect(mail_instance).to receive(:deliver_later)

        execute
      end
    end

    context 'when allowlisted user gets throttled' do
      let(:allowlist) { [user.username] }

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

        expect(user.banned?).to eq(false)
      end

      it 'does not log any event' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        execute
      end

      it 'does not send an email to admins', :mailer do
        expect(Notify).not_to receive(:user_auto_banned_email)

        execute
      end
    end
  end

  private

  def mock_throttled_calls(resource, peek_result:, result:)
    key = :unique_project_downloads_for_application
    args = {
      scope: user,
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
