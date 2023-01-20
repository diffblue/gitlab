# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin unsubscribes from notification", feature_category: :user_profile do
  let_it_be(:user) { create(:user) }
  let_it_be(:urlsafe_email) { Base64.urlsafe_encode64(user.email) }

  before do
    stub_const('NOTIFICATION_TEXT', 'You have been unsubscribed from receiving GitLab administrator notifications.')

    sign_in(user)

    visit(unsubscribe_path(urlsafe_email))
  end

  it "unsubscribes from notifications" do
    perform_enqueued_jobs do
      click_button("Unsubscribe")
    end

    last_email = ActionMailer::Base.deliveries.last

    expect(page).to have_current_path(root_path, ignore_query: true)
    expect(last_email.text_part.body.decoded).to include(NOTIFICATION_TEXT)
  end
end
