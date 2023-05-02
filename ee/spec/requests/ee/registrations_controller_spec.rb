# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RegistrationsController, type: :request, feature_category: :system_access do
  before do
    allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)
    allow(::Arkose::Settings).to receive(:enabled_for_signup?).and_return(true)
  end

  describe 'POST #create' do
    let_it_be(:user_attrs) { build_stubbed(:user).slice(:first_name, :last_name, :username, :email, :password) }

    subject(:create_user) { post user_registration_path, params: { user: user_attrs } }

    it_behaves_like 'creates a user with ArkoseLabs risk band on signup request' do
      let(:registration_path) { user_registration_path }
    end

    describe 'identity verification' do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'hard')
        stub_application_setting(require_admin_approval_after_user_signup: false)
        allow(::Arkose::Settings).to receive(:enabled_for_signup?).and_return(false)
      end

      context 'when identity verification is turned off' do
        let_it_be(:devise_token) { Devise.friendly_token }

        before do
          stub_feature_flags(identity_verification: false)
          allow(Devise).to receive(:friendly_token).and_return(devise_token)
        end

        describe 'sending confirmation instructions' do
          it 'sends Devise confirmation instructions' do
            expect { create_user }.to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
          end

          it 'does not send custom confirmation instructions' do
            expect(::Notify).not_to receive(:confirmation_instructions_email)

            create_user
          end

          it 'sets the confirmation_sent_at time' do
            freeze_time do
              create_user
              user = User.find_by_username(user_attrs[:username])

              expect(user.confirmation_sent_at).to eq(Time.current)
            end
          end

          it 'sets the confirmation_token to the unencrypted Devise token' do
            create_user
            user = User.find_by_username(user_attrs[:username])

            expect(user.confirmation_token).to eq(devise_token)
          end
        end

        describe 'setting a session variable' do
          it 'does not set the `verification_user_id` session variable' do
            create_user

            expect(request.session.has_key?(:verification_user_id)).to eq(false)
          end
        end

        describe 'redirection' do
          it 'redirects to the `users_almost_there_path`' do
            create_user

            expect(response).to redirect_to(users_almost_there_path(email: user_attrs[:email]))
          end
        end
      end

      context 'when identity verification is turned on' do
        let_it_be(:custom_token) { '123456' }
        let_it_be(:encrypted_token) { Devise.token_generator.digest(User, user_attrs[:email], custom_token) }

        before do
          stub_feature_flags(identity_verification: true)
          allow_next_instance_of(::Users::EmailVerification::GenerateTokenService) do |srvc|
            allow(srvc).to receive(:generate_token).and_return(custom_token)
          end
        end

        describe 'sending confirmation instructions' do
          it 'does not send Devise confirmation instructions' do
            expect { create_user }.not_to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
          end

          it 'sends custom confirmation instructions' do
            expect(::Notify).to receive(:confirmation_instructions_email)
              .with(user_attrs[:email], token: custom_token).once.and_call_original

            create_user
          end

          it 'sets the confirmation_sent_at time' do
            freeze_time do
              create_user
              user = User.find_by_username(user_attrs[:username])

              expect(user.confirmation_sent_at).to eq(Time.current)
            end
          end

          it 'sets the confirmation_token to the encrypted custom token' do
            create_user
            user = User.find_by_username(user_attrs[:username])

            expect(user.confirmation_token).to eq(encrypted_token)
          end
        end

        describe 'preventing token collisions' do
          it 'does not raise an error when an identical token exists in the database' do
            create_user

            user_attrs = build_stubbed(:user).slice(:first_name, :last_name, :username, :email, :password)

            expect { post user_registration_path, params: { user: user_attrs } }.not_to raise_error
          end
        end

        describe 'setting a session variable' do
          it 'sets the `verification_user_id` session variable' do
            create_user
            user = User.find_by_username(user_attrs[:username])

            expect(request.session[:verification_user_id]).to eq(user.id)
          end
        end

        describe 'handling sticking' do
          it 'sticks or unsticks the request' do
            allow(User.sticking).to receive(:stick_or_unstick_request)

            create_user

            user = User.find_by_username(user_attrs[:username])
            expect(User.sticking)
              .to have_received(:stick_or_unstick_request)
              .with(request.env, :user, user.id)
          end
        end

        describe 'redirection' do
          it 'redirects to the `identity_verification_path`' do
            create_user

            expect(response).to redirect_to(identity_verification_path)
          end
        end

        context 'when user is not persisted' do
          before do
            create(:user, email: user_attrs[:email])
          end

          it 'does not try to send custom confirmation instructions' do
            expect_next_instance_of(Users::EmailVerification::SendCustomConfirmationInstructionsService) do |service|
              expect(service).not_to receive(:send_instructions)
            end

            create_user
          end
        end
      end
    end

    context 'with onboarding progress' do
      before do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)
        allow(::Arkose::Settings).to receive(:enabled_for_signup?).and_return(false)
      end

      context 'when ensure_onboarding is enabled' do
        it 'sets onboarding' do
          create_user

          created_user = User.find_by(email: user_attrs[:email])
          expect(created_user.onboarding_in_progress).to be_truthy
        end
      end

      context 'when ensure_onboarding is disabled' do
        before do
          stub_feature_flags(ensure_onboarding: false)
        end

        it 'does not set onboarding' do
          create_user

          created_user = User.find_by(email: user_attrs[:email])
          expect(created_user.onboarding_in_progress).to be_falsey
        end
      end
    end
  end
end
