# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::ConfirmService, feature_category: :user_management do
  describe '#execute' do
    it 'records an audit event when confirmation is sent' do
      user = create(:user)
      unconfirmed_email = 'foobar@gitlab.com'

      expect(::Gitlab::Audit::Auditor).to(receive(:audit).with(hash_including({
        name: 'email_confirmation_sent',
        message: 'Confirmation instructions sent to: foobar@gitlab.com',
        additional_details: hash_including({
          current_email: user.email,
          target_type: 'Email',
          unconfirmed_email: unconfirmed_email
        })
      })).and_call_original)

      described_class.new(user).execute(user.emails.create!(email: unconfirmed_email))
    end
  end
end
