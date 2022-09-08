# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LicenseMailer do
  include EmailSpec::Matchers

  let(:recipients) { %w(admin@example.com another_admin@example.com) }

  let_it_be(:license) { create_current_license({ plan: License::STARTER_PLAN, restrictions: { active_user_count: 21 } }) }

  describe '#approaching_active_user_count_limit' do
    let(:subject_text) { 'Your subscription is nearing its user limit' }
    let(:subscription_name) { 'GitLab Enterprise Edition Starter' }
    let(:active_user_count) { 20 }

    subject { described_class.approaching_active_user_count_limit(recipients) }

    before do
      allow(license).to receive(:daily_billable_users_count).and_return(active_user_count)
      allow(License).to receive(:current).and_return(license)
    end

    context 'when license is present' do
      it { is_expected.to have_subject subject_text }
      it { is_expected.to bcc_to recipients }
      it { is_expected.to have_body_text "your subscription #{subscription_name}" }
      it { is_expected.to have_body_text "You have #{active_user_count} active users" }
      it { is_expected.to have_body_text "the user limit of #{license.restricted_user_count}" }
    end

    context 'when license is not present' do
      it 'does not send email' do
        expect { subject }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'when send with I18n.default_locale' do
      let(:users) { [create(:user, preferred_language: :zh_CN, email: '123@abc'), create(:user, preferred_language: :zh_CN, email: 'hjk@123')] }
      let(:recipients) { [users[0].email, users[1].email] }

      it { is_expected.to have_subject subject_text }
      it { is_expected.to bcc_to recipients }
      it { is_expected.to have_body_text "your subscription #{subscription_name}" }
      it { is_expected.to have_body_text "You have #{active_user_count} active users" }
      it { is_expected.to have_body_text "the user limit of #{license.restricted_user_count}" }
    end
  end
end
