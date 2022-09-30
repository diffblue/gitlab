# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::UserCap do
  include EmailSpec::Matchers

  let_it_be(:user) { create(:user) }

  describe "#user_cap_reached" do
    subject(:email) { Notify.user_cap_reached(user.id) }

    it "sends mail with expected contents" do
      expect(email).to have_subject('Important information about usage on your GitLab instance')
      expect(email).to be_delivered_to([user.notification_email_or_default])
      expect(email).to have_body_text('Your GitLab instance has reached the maximum allowed')
      expect(email).to have_body_text('Adjust the user cap setting on your instance')
    end
  end
end
