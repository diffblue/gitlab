# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::AbandonedTrialNotification, feature_category: :onboarding do
  include EmailSpec::Matchers

  let_it_be(:user) { build(:user) }
  let_it_be(:email_subject) { 'Help us improve GitLab' }
  let_it_be(:email_body_header) { 'How can we make GitLab better?' }

  subject(:email) { Notify.abandoned_trial_notification(user.id) }

  describe '#abandoned_trial_notification' do
    context 'when user exists' do
      before do
        allow(User).to receive(:find_by_id).and_return(user)
      end

      it 'sends mail with expected contents' do
        expect(email).to have_subject(email_subject)

        expect(email).to have_body_text(email_body_header)

        expect(email).to have_body_text("You recently created a GitLab account, but haven't been " \
                                        "active for a while. We'd love to know how we can make " \
                                        'GitLab better for you. This anonymous survey should take ' \
                                        'less than 5 minutes of your time.')

        expect(email).to have_body_text('Take the survey')
        expect(email).to have_body_text('https://gitlab.fra1.qualtrics.com/jfe/form/SV_4O78MWXKDixtN7o')

        expect(email).to have_body_text('If you no longer wish to receive marketing emails from us, ' \
                                        'you can')

        expect(email).to have_body_text('unsubscribe')
        expect(email).to have_body_text('at any time')
        expect(email).to have_body_text('%tag_unsubscribe_url%')

        expect(email).to be_delivered_to([user.notification_email_or_default])
      end
    end

    context 'when user does not exist' do
      it 'does not send mail' do
        expect(email).not_to have_subject(email_subject)
        expect(email).not_to have_body_text(email_body_header)
        expect(email).not_to be_delivered_to([user.notification_email_or_default])
      end
    end
  end
end
