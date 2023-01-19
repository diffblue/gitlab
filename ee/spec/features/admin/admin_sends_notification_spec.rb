# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin sends notification", :js, :sidekiq_might_not_need_inline, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }

  before do
    stub_const('NOTIFICATION_TEXT', 'Your project has been moved.')

    group.add_developer(user)
    group.add_developer(user2)

    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)

    visit(admin_email_path)

    ActionMailer::Base.deliveries.clear
  end

  it "sends notification" do
    perform_enqueued_jobs do
      fill_in(:subject, with: "My Subject")
      fill_in(:body, with: NOTIFICATION_TEXT)

      click_button(_('Select group or project'))

      wait_for_requests

      within('[data-testid="base-dropdown-menu"]') do
        expect(page).to have_content(_('All groups and projects'))
        expect(page).to have_content(group.name)
        expect(page).to have_content(project.name)

        page.find('li[role="option"]', text: group.name).click
      end

      click_button("Send message")
    end

    emails = ActionMailer::Base.deliveries
    emails_to = emails.flat_map(&:to)
    user_emails = group.users.map(&:email)

    expect(emails_to).to match_array(user_emails)
    expect(emails.last.text_part.body.decoded).to include(NOTIFICATION_TEXT)
  end
end
