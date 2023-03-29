# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SessionsController, feature_category: :system_access do
  describe '#create' do
    let_it_be(:user) { create(:user, :unconfirmed) }

    subject(:sign_in) do
      post user_session_path(user: { login: user.username, password: user.password })
    end

    context 'when identity verification is turned off' do
      before do
        allow_next_found_instance_of(User) do |user|
          allow(user).to receive(:identity_verification_enabled?).and_return(false)
        end
      end

      it { is_expected.to redirect_to(root_path) }

      it 'does not set the `verification_user_id` session variable' do
        sign_in

        expect(request.session.has_key?(:verification_user_id)).to eq(false)
      end
    end

    context 'when identity verification is turned on' do
      before do
        allow_next_found_instance_of(User) do |user|
          allow(user).to receive(:identity_verification_enabled?).and_return(true)
        end
      end

      it { is_expected.to redirect_to(identity_verification_path) }

      it 'sets the `verification_user_id` session variable' do
        sign_in

        expect(request.session[:verification_user_id]).to eq(user.id)
      end

      context 'when the user is verified' do
        before do
          allow_next_found_instance_of(User) do |user|
            allow(user).to receive(:identity_verified?).and_return(true)
          end
        end

        it { is_expected.to redirect_to(root_path) }
      end

      context 'when the user is locked' do
        before do
          user.lock_access!
        end

        it { is_expected.not_to have_gitlab_http_status(:redirect) }
      end

      context 'when the user is a GitLab QA user' do
        before do
          allow(Gitlab::Qa).to receive(:request?).and_return(true)
        end

        it { is_expected.not_to redirect_to(identity_verification_path) }
      end
    end
  end
end
