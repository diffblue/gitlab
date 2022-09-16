# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::IdentityVerification do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  describe 'confirmation_instructions_email' do
    let_it_be(:user) { create(:user) }
    let_it_be(:token) { '123456' }

    subject do
      Notify.confirmation_instructions_email(user.email, token: token)
    end

    it_behaves_like 'an email sent from GitLab'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject s_('IdentityVerification|Confirm your email address')
    end

    it 'includes the token' do
      is_expected.to have_body_text token
    end

    it 'includes the expiration time' do
      is_expected.to have_body_text format(s_('IdentityVerification|Your verification code expires after '\
        '%{expires_in_minutes} minutes.'), expires_in_minutes: 60)
    end
  end
end
