# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::UserCap do
  include EmailSpec::Matchers

  let_it_be(:user) { create(:user) }

  describe "#user_cap_reached" do
    subject { Notify.user_cap_reached(user.id) }

    it { is_expected.to have_subject('Important information about usage on your GitLab instance') }
    it { is_expected.to be_delivered_to([user.notification_email]) }
    it { is_expected.to have_body_text('Your GitLab instance has reached the maximum allowed') }
    it { is_expected.to have_body_text('user cap') }
  end
end
