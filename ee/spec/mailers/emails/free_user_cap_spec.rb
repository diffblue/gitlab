# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::FreeUserCap, feature_category: :experimentation_conversion do
  include EmailSpec::Matchers

  let_it_be(:user) { create :user }
  let_it_be(:namespace) { create :namespace, name: "foobar" }
  let(:checked_at) { "1969-04-20 13:37:42 UTC" }

  describe "#over_free_user_limit_email" do
    subject(:email) { Notify.over_free_user_limit_email user, namespace, checked_at }

    it "sends mail with expected contents" do
      allow(Namespaces::FreeUserCap).to receive(:dashboard_limit).and_return(10)

      expect(email).to have_subject("You've reached your member limit!")
      expect(email).to have_body_text("It looks like you've reached your limit")
      expect(email).to have_body_text("of 10 members")
      expect(email).to have_body_text("according to the check we ran on April 20, 1969 13:37")
      expect(email).to have_body_text("Manage members")
      expect(email).to have_body_text("Explore paid plans")
      expect(email).to have_body_text("foobar/-/billings?source=over-user-limit-email-btn-cta")
      expect(email).to have_body_text("foobar/-/billings?source=over-user-limit-email-upgrade-link")
      expect(email).to have_body_text("usage_quotas#seats-quota-tab")
      expect(email).to have_body_text("-/trials/new?namespace_id=#{namespace.id}")
      expect(email).to be_delivered_to([user.notification_email_or_default])
    end
  end
end
