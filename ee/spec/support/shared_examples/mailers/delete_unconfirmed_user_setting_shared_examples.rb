# frozen_string_literal: true

RSpec.shared_examples 'an email with information about unconfirmed user settings' do
  using RSpec::Parameterized::TableSyntax

  context 'when delete unconfirmed users settings are present' do
    where(
      :delete_unconfirmed_users_license,
      :delete_unconfirmed_users_application_setting,
      :email_confirmation_setting,
      :delete_after_days,
      :result
    ) do
      true  | true  | 'hard' | 7 | true
      true  | true  | 'soft' | 7 | true
      true  | true  | 'off'  | 7 | false
      false | true  | 'hard' | 7 | false
      true  | false | 'hard' | 7 | false
      false | false | 'hard' | 7 | false
    end

    with_them do
      before do
        stub_licensed_features(delete_unconfirmed_users: delete_unconfirmed_users_license)

        stub_application_setting(delete_unconfirmed_users: delete_unconfirmed_users_application_setting)
        stub_application_setting(unconfirmed_users_delete_after_days: delete_after_days)
        stub_application_setting_enum('email_confirmation_setting', email_confirmation_setting)
      end

      it "has the correct email body contents" do
        email_bodies = [mail.text_part, mail.html_part]

        if result == true
          expect(email_bodies).to all(have_text(
            format(
              _("You must confirm your email within %{cut_off_days} days of signing up"),
              cut_off_days: delete_after_days
            )
          ))
        else
          email_bodies.each do |body|
            expect(body).not_to have_text(
              format(
                _("You must confirm your email within %{cut_off_days} days of signing up"),
                cut_off_days: delete_after_days
              )
            )
          end
        end
      end
    end
  end
end
