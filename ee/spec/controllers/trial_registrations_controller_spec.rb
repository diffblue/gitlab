# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialRegistrationsController do
  let(:com) { true }

  before do
    allow(Gitlab).to receive(:com?).and_return(com)
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

      context 'when customer is not authenticated' do
        it { is_expected.to render_template(:new) }
      end
    end

    context 'when customer is authenticated' do
      context 'when about_your_company_registration_flow is disabled' do
        before do
          stub_feature_flags(about_your_company_registration_flow: false)
          sign_in(logged_in_user) if logged_in_user.present?
          get :new, params: get_params
        end

        let_it_be(:logged_in_user) { create(:user) }

        it { is_expected.to redirect_to(new_trial_url) }

        context 'when there are additional query params' do
          let(:get_params) { { glm_source: 'some_source', glm_content: 'some_content' } }

          it { is_expected.to redirect_to(new_trial_url(get_params)) }
        end
      end

      context 'when about_your_company_registration_flow is enabled' do
        before do
          stub_feature_flags(about_your_company_registration_flow: true)
          sign_in(logged_in_user) if logged_in_user.present?
          get :new, params: get_params
        end

        let_it_be(:logged_in_user) { create(:user) }

        it { is_expected.to redirect_to(new_users_sign_up_company_path(trial: true)) }
      end
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
      stub_application_setting(send_user_confirmation_email: true)
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

        expect(User.last.name).to eq("#{user_params[:first_name]} #{user_params[:last_name]}")
      end
    end

    context 'applying the onboarding=true parameter' do
      it 'adds the parameter' do
        redirect_path = new_trial_path(glm_source: 'about.gitlab.com', glm_content: 'default-saas-trial')
        controller.store_location_for(:user, redirect_path)
        post_create
        expect(controller.stored_location_for(:user)).to eq(redirect_path + '&onboarding=true')
      end
    end
  end
end
