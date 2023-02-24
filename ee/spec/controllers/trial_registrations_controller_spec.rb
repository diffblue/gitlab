# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialRegistrationsController, feature_category: :system_access do
  include FullNameHelper

  let(:com) { true }

  before do
    allow(Gitlab).to receive(:com?).and_return(com)
    stub_feature_flags(arkose_labs_signup_challenge: false)
  end

  shared_examples 'a dot-com only feature' do
    let(:success_status) { :ok }

    context 'when not on gitlab.com and not in development environment' do
      let(:com) { false }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when on gitlab.com or in dev environment' do
      it { is_expected.to have_gitlab_http_status(success_status) }
    end
  end

  describe '#new' do
    let(:logged_in_user) { nil }
    let(:get_params) { {} }

    context 'a dot-com only feature' do
      before do
        sign_in(logged_in_user) if logged_in_user.present?
        get :new, params: get_params
      end

      subject { response }

      it_behaves_like 'a dot-com only feature'
    end

    context 'when customer is not authenticated' do
      before do
        get :new, params: get_params
      end

      it 'renders template' do
        is_expected.to render_template(:new)
      end
    end

    context 'when customer is authenticated' do
      before do
        sign_in(logged_in_user) if logged_in_user.present?
        get :new, params: get_params
      end

      let_it_be(:logged_in_user) { create(:user) }

      it { is_expected.to redirect_to(new_trial_url) }
    end
  end

  describe '#create', :clean_gitlab_redis_rate_limiting do
    let(:user_params) do
      {
        first_name: 'John',
        last_name: 'Doe',
        email: 'johnd2019@local.dev',
        username: 'johnd',
        password: User.random_password
      }
    end

    before do
      stub_application_setting_enum('email_confirmation_setting', 'hard')
    end

    subject(:post_create) { post :create, params: { user: user_params } }

    it_behaves_like 'a dot-com only feature' do
      let(:success_status) { :found }
    end

    it 'marks the account as unconfirmed' do
      post_create

      expect(User.last).not_to be_confirmed
    end

    context 'derivation of name' do
      it 'sets name from first and last name' do
        post_create

        expect(User.last.name).to eq full_name(user_params[:first_name], user_params[:last_name])
      end
    end
  end
end
