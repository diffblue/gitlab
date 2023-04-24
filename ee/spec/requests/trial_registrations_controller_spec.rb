# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialRegistrationsController, :saas, feature_category: :purchase do
  describe 'POST create' do
    before do
      stub_feature_flags(arkose_labs_signup_challenge: false)
    end

    let(:user_params) do
      build_stubbed(:user)
        .slice(:first_name, :last_name, :email, :username, :password)
    end

    context 'when email_opted_in does not exist in params' do
      it 'sets user email_opted_in to false' do
        post trial_registrations_path, params: { user: user_params }

        expect(response).to have_gitlab_http_status(:found)
        expect(User.last.email_opted_in).to be_nil
      end
    end

    context 'when email_opted_in is true in params' do
      it 'sets user email_opted_in to true' do
        post trial_registrations_path, params: {
          user: user_params.merge(email_opted_in: true)
        }

        expect(response).to have_gitlab_http_status(:found)
        expect(User.last.email_opted_in).to be true
      end
    end

    context 'with snowplow tracking', :snowplow do
      subject(:post_create) do
        post trial_registrations_path, params: { user: user_params }
      end

      context 'when the password is weak' do
        let(:user_params) { super().merge(password: '1') }

        it 'does not track failed form submission' do
          post_create

          expect_no_snowplow_event(
            category: described_class.name,
            action: 'successfully_submitted_form'
          )
        end
      end

      context 'when the password is not weak' do
        it 'tracks successful form submission' do
          post_create

          expect_snowplow_event(
            category: described_class.name,
            action: 'successfully_submitted_form',
            user: User.find_by(email: user_params[:email])
          )
        end
      end

      context 'with email confirmation' do
        before do
          stub_application_setting(require_admin_approval_after_user_signup: false)
          stub_feature_flags(identity_verification: false)
          allow(User).to receive(:allow_unconfirmed_access_for).and_return 0
        end

        context 'when email confirmation settings is set to `soft`' do
          before do
            stub_application_setting_enum('email_confirmation_setting', 'soft')
          end

          it 'does not track an almost there redirect' do
            post_create

            expect_no_snowplow_event(
              category: described_class.name,
              action: 'render',
              user: User.find_by(email: user_params[:email])
            )
          end
        end

        context 'when email confirmation settings is not set to `soft`' do
          before do
            stub_application_setting_enum('email_confirmation_setting', 'hard')
          end

          it 'tracks an almost there redirect' do
            post_create

            expect_snowplow_event(
              category: described_class.name,
              action: 'render',
              user: User.find_by(email: user_params[:email])
            )
          end
        end
      end
    end

    it_behaves_like 'creates a user with ArkoseLabs risk band on signup request' do
      let(:user_attrs) { user_params }
      let(:registration_path) { trial_registrations_path }
    end
  end
end
