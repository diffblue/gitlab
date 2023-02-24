# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::CaptchaCheck, feature_category: :system_access do
  let_it_be(:username) { 'TestCaptcha' }
  let_it_be(:email) { 'test_email@email.com' }
  let_it_be_with_reload(:user) { create(:user, username: username, email: email) }

  describe 'POST users/captcha_check' do
    context 'when the feature flag arkose_labs_login_challenge is disabled' do
      before do
        stub_feature_flags(arkose_labs_login_challenge: false)
      end

      it 'does return not found status' do
        post api('/users/captcha_check'), params: { username: username }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the feature flag arkose_labs_login_challenge is enabled' do
      before do
        stub_feature_flags(arkose_labs_login_challenge: true)
      end

      context 'when the username is invalid' do
        let(:invalid_username) { 'invalidUsername' }

        it 'does return 200 OK status to prevent enumeration' do
          post api('/users/captcha_check'), params: { username: invalid_username }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']).to be_truthy
        end
      end

      context 'when the username has a dot' do
        let_it_be(:username) { 'valid.Username' }
        let_it_be(:dot_user) { create(:user, username: username) }

        it 'does return 200 status' do
          post api('/users/captcha_check'), params: { username: username }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when the username is nil' do
        let_it_be(:username) { nil }

        it 'does return 200 OK status to prevent enumeration' do
          post api('/users/captcha_check'), params: { username: username }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']).to be_truthy
        end
      end

      context 'when the username is an array' do
        let_it_be(:username) { %w[guess1 guess2 root] }

        it 'does return 200 OK status to prevent enumeration' do
          post api('/users/captcha_check'), params: { username: username }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when the email is valid' do
        it 'returns status ok' do
          post api('/users/captcha_check'), params: { username: email }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when the email is unknown' do
        let(:unknown_email) { 'unknown_email@email.com' }

        it 'returns 200 OK status to prevent enumeration' do
          post api('/users/captcha_check'), params: { username: unknown_email }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']).to be_truthy
        end
      end

      context 'when the email is invalid' do
        let(:invalid_email) { 'invalid_email@' }

        it 'returns 200 OK status to prevent enumeration' do
          post api('/users/captcha_check'), params: { username: invalid_email }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']).to be_truthy
        end
      end

      context 'when the user meets the criteria for the captcha check' do
        before do
          user.last_sign_in_at = nil
        end

        it 'does return true' do
          post api('/users/captcha_check'), params: { username: username }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']).to be_truthy
        end
      end

      context 'when the user does not meets the criteria for the captcha check' do
        before do
          user.last_sign_in_at = Date.today - 2.months
          user.last_sign_in_ip = '192.168.1.1'
          user.save!
        end

        it 'does return true' do
          post api('/users/captcha_check'), params: { username: username }, headers: { 'REMOTE_ADDR' => '192.168.1.1' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']).to be_falsey
        end
      end

      context 'when the user reach the rate limit' do
        before do
          user.last_sign_in_at = Date.today - 2.months
          user.last_sign_in_ip = '192.168.1.1'
          user.save!
        end

        it 'does return true' do
          allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
          post api('/users/captcha_check'), params: { username: username }, headers: { 'REMOTE_ADDR' => '192.168.1.1' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['result']).to be_truthy
        end
      end
    end
  end
end
