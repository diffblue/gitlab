# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::FreeUserCap do
  include EmailSpec::Matchers

  let_it_be(:user) { create :user }
  let_it_be(:namespace) { create :namespace, name: "foobar" }

  describe "#reached_free_user_limit_email" do
    subject(:email) { Notify.reached_free_user_limit_email user, namespace }

    it "sends mail with expected contents" do
      allow(Namespaces::FreeUserCap).to receive(:dashboard_limit).and_return(10)

      expect(email).to have_subject("You've reached your member limit!")
      expect(email).to have_body_text("Looks like you've reached your limit")
      expect(email).to have_body_text("of 10 members")
      expect(email).to have_body_text("Manage members")
      expect(email).to have_body_text("Explore paid plans")
      expect(email).to have_body_text("foobar/-/billings")
      expect(email).to have_body_text("usage_quotas#seats-quota-tab")
      expect(email).to have_body_text("-/trials/new")
      expect(email).to be_delivered_to([user.notification_email_or_default])
    end
  end
end
