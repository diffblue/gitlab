# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RegistrationsController, type: :request do
  describe 'POST #create' do
    let_it_be(:user_attrs) { build(:user).slice(:first_name, :last_name, :username, :email, :password) }

    let(:arkose_labs_params) { { arkose_labs_token: 'arkose-labs-token' } }
    let(:user_params) { { user: user_attrs }.merge(arkose_labs_params) }

    let(:json_response) do
      Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response.json')))
    end

    subject(:create_user) { post user_registration_path, params: user_params }

    shared_examples 'creates the user' do
      it 'creates the user' do
        create_user

        created_user = User.find_by(email: user_attrs[:email])
        expect(created_user).not_to be_nil
      end
    end

    shared_examples 'renders new action with an alert flash' do
      it 'renders new action with an alert flash', :aggregate_failures do
        create_user

        expect(flash[:alert]).to include(_('Complete verification to sign up.'))
        expect(response).to render_template(:new)
      end
    end

    context 'when arkose labs session token verification is needed' do
      let(:verify_response) { Arkose::VerifyResponse.new(json_response) }
      let(:service_response) { ServiceResponse.success(payload: { response: verify_response }) }

      before do
        allow_next_instance_of(Arkose::TokenVerificationService) do |instance|
          allow(instance).to receive(:execute).and_return(service_response)
        end
      end

      context 'when arkose_labs_token verification succeeds' do
        it_behaves_like 'creates the user'

        it "records the user's data from Arkose Labs" do
          expect { create_user }.to change { UserCustomAttribute.count }.from(0)
        end
      end

      context 'when verification fails' do
        let(:service_response) { ServiceResponse.error(message: 'Captcha was not solved') }

        it_behaves_like 'renders new action with an alert flash'

        it "does not record the user's data from Arkose Labs" do
          expect(Arkose::RecordUserDataService).not_to receive(:new)

          create_user
        end
      end
    end

    context 'when arkose labs session token verification is skipped' do
      shared_examples 'skips verification and data recording' do
        it 'skips verification and data recording', :aggregate_failures do
          expect(Arkose::TokenVerificationService).not_to receive(:new)
          expect(Arkose::RecordUserDataService).not_to receive(:new)

          create_user
        end
      end

      context 'when :arkose_labs_signup_challenge feature flag is disabled' do
        before do
          stub_feature_flags(arkose_labs_signup_challenge: false)
        end

        it_behaves_like 'creates the user'

        it_behaves_like 'skips verification and data recording'
      end

      context 'when arkose_labs_token param is not present' do
        let(:arkose_labs_params) { {} }

        it_behaves_like 'renders new action with an alert flash'

        it_behaves_like 'skips verification and data recording'
      end
    end

    describe 'identity verification' do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'hard')
        stub_application_setting(require_admin_approval_after_user_signup: false)
        stub_feature_flags(soft_email_confirmation: false)
        stub_feature_flags(arkose_labs_signup_challenge: false)
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
        let_it_be(:encrypted_token) { Devise.token_generator.digest(User, :confirmation_token, custom_token) }

        before do
          stub_feature_flags(identity_verification: true)
          allow_next_instance_of(::Users::EmailVerification::GenerateTokenService, attr: :confirmation_token) do |srvc|
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

        describe 'setting a session variable' do
          it 'sets the `verification_user_id` session variable' do
            create_user
            user = User.find_by_username(user_attrs[:username])

            expect(request.session[:verification_user_id]).to eq(user.id)
          end
        end

        describe 'redirection' do
          it 'redirects to the `identity_verification_path`' do
            create_user

            expect(response).to redirect_to(identity_verification_path)
          end
        end
      end
    end

    context 'with onboarding progress' do
      before do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)
        stub_feature_flags(arkose_labs_signup_challenge: false)
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
