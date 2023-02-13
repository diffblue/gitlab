# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::AdminNotification, feature_category: :insider_threat do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  describe 'user_auto_banned_email' do
    let_it_be(:alerted_user) { create(:user) }
    let_it_be(:alerted_user_id) { alerted_user.id }
    let_it_be(:user) { create(:user) }

    let(:max_project_downloads) { 5 }
    let(:time_period) { 600 }
    let(:auto_ban_enabled) { true }
    let(:group) { nil }

    subject do
      Notify.user_auto_banned_email(
        alerted_user_id, user.id,
        max_project_downloads: max_project_downloads,
        within_seconds: time_period,
        auto_ban_enabled: auto_ban_enabled,
        group: group
      )
    end

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'is sent to the alerted user' do
      is_expected.to deliver_to alerted_user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject "We've detected unusual activity"
    end

    it 'includes the reason' do
      is_expected.to have_body_text "We want to let you know #{user.name} has exceeded the Git rate limit due to them \
        downloading more than 5 project repositories within 10 minutes."
    end

    context 'when threshold is 1 and interval is 1 minute' do
      let(:max_project_downloads) { 1 }
      let(:time_period) { 60 }

      it 'uses singular form' do
        is_expected.to have_body_text "1 project repository within 1 minute."
      end
    end

    context 'when interval is less than a minute' do
      let(:time_period) { 30 }

      it 'uses the correct unit' do
        is_expected.to have_body_text "5 project repositories within 30 seconds."
      end
    end

    it 'includes the scope of the ban' do
      is_expected.to have_body_text "Because you enabled auto-banning, we have also automatically banned this user \
        from your GitLab instance"
    end

    it 'includes a link to unban the user' do
      is_expected.to have_body_text admin_users_url(filter: 'banned')
    end

    it 'includes a link to change the settings' do
      is_expected.to have_body_text reporting_admin_application_settings_url
    end

    it 'includes the email reason' do
      is_expected.to have_body_text %r{You're receiving this email because of your account on <a .*>localhost<\/a>}
    end

    context 'when auto-ban is disabled' do
      let(:auto_ban_enabled) { false }

      it 'does not include the scope of the ban' do
        is_expected.not_to have_body_text "Because you enabled auto-banning, we have also automatically banned this \
          user from your GitLab instance"
      end

      it 'does not include a link to unban the user' do
        is_expected.not_to have_body_text admin_users_url(filter: 'banned')
      end
    end

    context 'when scoped to a group' do
      let(:group) { create(:group) }

      it 'includes the scope of the ban' do
        is_expected.to have_body_text "Because you enabled auto-banning, we have also automatically banned this user \
          from your group (#{group.name})"
      end

      it 'includes a link to unban the user' do
        is_expected.to have_body_text group_group_members_url(group, tab: 'banned')
      end

      it 'includes a link to change the settings' do
        is_expected.to have_body_text group_settings_reporting_url(group)
      end
    end

    context 'when alerted user does not exist anymore' do
      let_it_be(:alerted_user_id) { non_existing_record_id }

      it_behaves_like 'no email is sent'
    end
  end
end
