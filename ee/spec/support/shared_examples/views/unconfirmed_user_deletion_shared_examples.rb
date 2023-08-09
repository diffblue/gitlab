# frozen_string_literal: true

RSpec.shared_examples_for 'page with unconfirmed user deletion information' do
  subject { render(template: template) }

  describe 'delete unconfirmed users is set' do
    let_it_be(:delete_after_days) { 7 }

    before do
      stub_licensed_features(delete_unconfirmed_users: true)
      stub_application_setting(delete_unconfirmed_users: true)
      stub_application_setting(delete_unconfirmed_users_after_days: delete_after_days)
      stub_application_setting_enum('email_confirmation_setting', 'hard')
    end

    it "shows the unconfirmed users text" do
      subject

      expect(rendered).to have_text(
        format(
          _("You must confirm your email within %{cut_off_days} days of signing up"),
          cut_off_days: delete_after_days
        )
      )
    end
  end
end
